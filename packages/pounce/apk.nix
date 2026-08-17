{
  lib,
  stdenv,
  callPackage,
  bun,
  cacert,
  jdk17,
  nodejs,
  version,
  src,
}: let
  android = callPackage ./android-sdk.nix {};

  # A phone that isn't a decade old. Dropping this builds all four ABIs for
  # roughly four times the wall clock and no benefit.
  abi = "arm64-v8a";

  apksigner = "${android.root}/build-tools/${android.buildToolsVersion}/apksigner";

  # Everything that needs the network, and nothing that doesn't.
  #
  # It has to be a fixed-output derivation, because that is the only way to get
  # network access, and this build cannot live without it: upstream commits no
  # android/ directory, so `expo prebuild` has to generate the Gradle project
  # first, and the project it generates then resolves several hundred Maven
  # artifacts from google()/mavenCentral()/jitpack against no lockfile.
  #
  # The price is that outputHash pins the result bit for bit, and two clean runs
  # have to agree. They do, but only after two things are taken out of the way —
  # see the manifest patch and the signingConfig patch below. An upstream
  # artifact moving underneath this still breaks the hash, which is why the
  # package is archived rather than built nightly.
  unsigned = stdenv.mkDerivation {
    pname = "pounce-apk-unsigned";
    inherit version src;

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-ferKcTP5VF+TFBt2ZJrTd60e3mGqGqmSl1KamjxTaHs=";

    nativeBuildInputs = [
      android.androidsdk
      bun
      jdk17 # Gradle 9 / AGP 8.12 floor
      nodejs # Gradle shells out to it for autolinking
    ];

    env =
      android.env
      // {
        JAVA_HOME = jdk17.home;
        EXPO_NO_TELEMETRY = "1";
        CI = "1";
        SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
      };

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export HOME=$NIX_BUILD_TOP/home
      export GRADLE_USER_HOME=$NIX_BUILD_TOP/gradle
      mkdir -p "$HOME" "$GRADLE_USER_HOME"

      # Install scripts run during the install itself, before anything can fix
      # them up, and they die on the /usr/bin/env shebang the sandbox has no
      # answer for. The packages carrying them are dev tooling (tree-sitter and
      # the like), so skipping is safe — verified rather than assumed: with and
      # without them the unsigned APK comes out byte for byte the same.
      bun install --frozen-lockfile --ignore-scripts

      # Same shebang, now fixable. Without this the expo CLI below exits 1 and
      # prints absolutely nothing, which is a memorable half hour.
      patchShebangs node_modules

      # expo-updates stamps assets/app.manifest with a fresh UUID and a wall
      # clock and offers no way to override either, which is one of the two
      # things that made two builds differ. Both only matter for choosing
      # between OTA updates, and this APK can reach none — the EAS project it
      # would poll belongs to upstream. --replace-fail so an upstream rewrite of
      # these lines fails the build rather than silently going random again.
      substituteInPlace node_modules/expo-updates/utils/build/createManifestForBuildAsync.js \
        --replace-fail 'id: crypto_1.default.randomUUID(),' \
                       'id: "00000000-0000-0000-0000-000000000000",' \
        --replace-fail 'commitTime: new Date().getTime(),' \
                       'commitTime: 0,'

      cd apps/mobile
      ../../node_modules/.bin/expo prebuild -p android --no-install
      cd android

      # The other one. Expo's template signs release with the debug keystore it
      # ships, and apksigner signs with RSASSA-PSS, whose salt is random — two
      # builds agreed on all 1807 zip entries and disagreed only inside the APK
      # Signing Block. So Gradle emits the APK unsigned and the derivation
      # wrapping this one signs it, where nondeterminism costs nothing.
      #
      # 'signingConfig signingConfigs.debug' appears in both the debug and the
      # release buildType, so the release one is reached through the comment
      # above it. Both greps are assertions: they fail the build if upstream
      # moves the anchor or the line, rather than leaving the APK signed and the
      # output hash unstable.
      grep -q 'signed-apk-android' app/build.gradle
      sed -i '/signed-apk-android/{n;s|^\( *\)signingConfig signingConfigs\.debug$|\1// signed by apk.nix instead|}' app/build.gradle
      test "$(grep -c 'signingConfig signingConfigs.debug' app/build.gradle)" -eq 1

      ./gradlew assembleRelease \
        -PreactNativeArchitectures=${abi} \
        -Dorg.gradle.jvmargs="-Xmx8g -XX:MaxMetaspaceSize=2g" \
        --no-daemon --console=plain

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp app/build/outputs/apk/release/app-release-unsigned.apk $out/

      # The well-known Android debug key every React Native template ships, and
      # the reason the signature below is a stable identity: reinstalling over a
      # previous build is an upgrade rather than a signature conflict.
      cp app/debug.keystore $out/

      runHook postInstall
    '';
  };
in
  stdenv.mkDerivation {
    pname = "pounce-apk";
    inherit version;

    dontUnpack = true;
    nativeBuildInputs = [jdk17];

    buildPhase = ''
      runHook preBuild

      ${apksigner} sign \
        --ks ${unsigned}/debug.keystore \
        --ks-pass pass:android \
        --ks-key-alias androiddebugkey \
        --key-pass pass:android \
        --in ${unsigned}/app-release-unsigned.apk \
        --out pounce-${version}-${abi}.apk

      ${apksigner} verify --print-certs pounce-${version}-${abi}.apk

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 pounce-${version}-${abi}.apk \
        $out/pounce-${version}-${abi}.apk
      runHook postInstall
    '';

    passthru = {
      inherit unsigned;
      updatePolicy = "skip";
    };

    meta = {
      description = "Pounce Android app, built from source as an installable APK";
      homepage = "https://use-pounce.com";
      license = lib.licenses.mit;
      maintainers = [];
      # Google ships the SDK build tools as x86_64 Linux binaries only.
      platforms = ["x86_64-linux"];
    };
  }
