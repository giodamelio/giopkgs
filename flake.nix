{
  description = "Misc packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ] (system:
        function (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }));

    # Collect passthru.tests from all packages into checks
    collectTests = packages:
      nixpkgs.lib.foldlAttrs (
        acc: name: pkg:
          acc
          // (
            if pkg ? passthru.tests
            then
              nixpkgs.lib.mapAttrs' (
                testName: test:
                  nixpkgs.lib.nameValuePair "${name}-${testName}" test
              )
              pkg.passthru.tests
            else {}
          )
      ) {}
      packages;
  in {
    packages = forAllSystems (
      pkgs:
        nixpkgs.lib.filesystem.packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage;
          directory = ./packages;
        }
    );

    checks = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"] (
      system:
        collectTests self.packages.${system}
    );

    overlays.default = final: _prev:
      nixpkgs.lib.filesystem.packagesFromDirectoryRecursive {
        inherit (final) callPackage;
        directory = ./packages;
      };

    devShells = forAllSystems (pkgs: let
      # Everything the update scripts shell out to. CI enters this shell rather
      # than installing tools ad hoc, so local and nightly runs cannot drift.
      updateTools = with pkgs; [
        nushell
        ast-grep # Structural search/rewrite of Nix files
        nix-update # Auto update version/src hashes for derivations
        nurl # Fetch a URL and print a Nix fetch statement with the correct hash
        prefetch-npm-deps # npmDepsHash without a build
        nodejs # inker regenerates npm lockfiles
        jq
        gh
        curl
        python3 # borgbackup/sync-deps.py
      ];
    in {
      update = pkgs.mkShell {buildInputs = updateTools;};

      default = pkgs.mkShell {
        buildInputs =
          updateTools
          ++ (with pkgs; [
            nix-init # Help scaffold new package automatically
            crate2nix # Help building Rust packages (adding this to handle building a single crate from a workspace)
            self.packages.${pkgs.system}.remind-me-to # Reminder checker
            prek # Git Hooks
            alejandra # Nix formatting
            shellcheck # Shell script linting
            statix # Nix linting
            deadnix # Find dead Nix code
          ]);
        shellHook = ''
          prek install
        '';
      };

      # Toolchain for building the Pounce Android app, which packages/pounce
      # deliberately does not cover. It cannot be a derivation: upstream commits
      # no android/ directory, so `expo prebuild` has to generate the Gradle
      # project first, and Gradle then resolves several hundred Maven artifacts
      # against google()/mavenCentral()/jitpack with no lockfile. Neither step
      # survives the sandbox, so this ships the tools and leaves the build impure.
      #
      #   nix develop .#android
      #   jj git clone https://github.com/pounce-ai/pounce && cd pounce
      #   bun install
      #   cd apps/mobile && bunx expo prebuild -p android --no-install
      #   cd android && ./gradlew assembleRelease -PreactNativeArchitectures=arm64-v8a
      #
      # The APK lands in app/build/outputs/apk/release/. Expo's template signs
      # release with the debug keystore it ships, so it installs as-is —
      # `adb install -r` it. Dropping the architectures flag builds all four ABIs
      # and takes roughly four times as long for no benefit on a real phone.
      android = let
        # androidenv needs a licence acceptance that has no business applying to
        # the package set the rest of the flake builds against.
        androidPkgs = import nixpkgs {
          inherit (pkgs.stdenv.hostPlatform) system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        # From the react-native pin apps/mobile carries — see that release's
        # gradle/libs.versions.toml, which is what expo-root-project reads. These
        # move when upstream bumps React Native, and Gradle says so loudly.
        buildToolsVersion = "36.0.0";
        ndkVersion = "27.1.12297006";

        # AGP 8.12's own default. Modules that never read
        # rootProject.ext.ndkVersion — expo-sqlite is one — fall back to it, and
        # AGP answers a missing NDK by trying to install one into the SDK, which
        # is a store path. Shipping both is what stops that.
        agpDefaultNdkVersion = "27.0.12077973";

        composition = androidPkgs.androidenv.composeAndroidPackages {
          # 36 is what the app targets. The older pair is for autolinked
          # community modules that read their own safeExtGet default instead of
          # the root project's — react-native-true-sheet asks for 35.0.0 — and
          # would otherwise send AGP off to install it into the store.
          platformVersions = ["36" "35"];
          buildToolsVersions = [buildToolsVersion "35.0.0"];
          includeNDK = true;
          ndkVersions = [ndkVersion agpDefaultNdkVersion];
          cmakeVersions = ["3.22.1"];
          includeEmulator = false;
          includeSystemImages = false;
          includeSources = false;
        };

        sdk = "${composition.androidsdk}/libexec/android-sdk";
      in
        androidPkgs.mkShell {
          buildInputs = with androidPkgs; [
            jdk17 # Gradle 9 / AGP 8.12 floor
            bun # the workspace resolves through bun.lock
            nodejs # expo prebuild, and Gradle shells out to it for autolinking
            android-tools # adb, to get the APK onto the phone
            composition.androidsdk
          ];

          ANDROID_HOME = sdk;
          ANDROID_SDK_ROOT = sdk;
          ANDROID_NDK_ROOT = "${sdk}/ndk/${ndkVersion}";
          JAVA_HOME = androidPkgs.jdk17.home;

          # AGP otherwise pulls its own aapt2 from Maven, and that binary is not
          # patched for NixOS. The one in build-tools is.
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/build-tools/${buildToolsVersion}/aapt2";

          # androidsdk only puts a subset on PATH, and apksigner and aapt2 —
          # the two worth having to inspect the APK you just built — aren't in it.
          shellHook = ''
            export PATH="${sdk}/build-tools/${buildToolsVersion}:$PATH"
          '';
        };
    });
  };
}
