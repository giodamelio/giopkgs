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

      # Working on the Pounce Android app by hand. `nix build .#pounce-apk`
      # builds the same APK unattended; this is for when you want to iterate,
      # and it is where the recipe that package automates came from:
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
        sdk = pkgs.callPackage ./packages/pounce/android-sdk.nix {};
      in
        pkgs.mkShell (sdk.env
          // {
            buildInputs = [
              pkgs.jdk17 # Gradle 9 / AGP 8.12 floor
              pkgs.bun # the workspace resolves through bun.lock
              pkgs.nodejs # expo prebuild, and Gradle shells out for autolinking
              pkgs.android-tools # adb, to get the APK onto the phone
              sdk.androidsdk
            ];

            JAVA_HOME = pkgs.jdk17.home;

            # androidsdk only puts a subset on PATH, and apksigner and aapt2 —
            # the two worth having to inspect the APK you just built — aren't in it.
            shellHook = ''
              export PATH="${sdk.root}/build-tools/${sdk.buildToolsVersion}:$PATH"
            '';
          });
    });
  };
}
