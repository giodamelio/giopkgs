{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  bun,
  alsa-lib,
  libpulseaudio,
  tesseract,
  ffmpeg,
  dbus,
  libx11,
  libxcursor,
  libxrandr,
  libxi,
  libxcb,
  libxkbcommon,
  wayland,
  pipewire,
  libGL,
  libgbm,
  openssl,
  openblas,
  onnxruntime,
  makeWrapper,
  # Tauri-specific deps
  gtk3,
  webkitgtk_4_1,
  libsoup_3,
  glib,
  glib-networking,
  librsvg,
  libayatana-appindicator,
  # Node/frontend build
  cacert,
}: let
  version = "app-v2.7.84";

  src = fetchFromGitHub {
    owner = "screenpipe";
    repo = "screenpipe";
    tag = version;
    hash = "sha256-WAvnSkniojqnqGf+MdVulAFkohbxLoBfAg0w/9bXnoU=";
  };

  # Build the Next.js frontend first
  frontend = stdenv.mkDerivation {
    pname = "screenpipe-app-frontend";
    inherit version src;

    nativeBuildInputs = [bun cacert];

    buildPhase = ''
      cd apps/screenpipe-app-tauri

      # Skip pre_build.js (downloads binaries we provide via Nix)
      export HOME=$TMPDIR
      bun install --frozen-lockfile

      # next.config.mjs refuses to build without the localization snapshot
      bun scripts/i18n/prepare.mjs

      # Build Next.js static export
      bun node_modules/next/dist/bin/next build
    '';

    installPhase = ''
      cp -r out $out
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-7tH0iUb1ZBSBD2qgLIe5t2EarjtjzHj8LWG/8oeeAsI=";
  };
in
  rustPlatform.buildRustPackage {
    pname = "screenpipe-app";
    inherit version src;

    cargoDeps = rustPlatform.fetchCargoVendor {
      name = "screenpipe-app-${version}";
      src = lib.fileset.toSource {
        root = ./.;
        fileset = ./Cargo.lock;
      };
      hash = "sha256-QlRjxgKZhFQ13QvsEp4DhRUBef8e6T7AqB0IyJycluc=";
    };

    # The Tauri app crate is at apps/screenpipe-app-tauri/src-tauri
    # but it references workspace crates via ../../../crates/
    # We need to build from the repo root with the right manifest
    postPatch = ''
      # Place the pre-built frontend where Tauri expects it
      cp -r ${frontend} apps/screenpipe-app-tauri/out

      # Create placeholder mlx.metallib (build.rs does this on non-macOS)
      touch apps/screenpipe-app-tauri/src-tauri/mlx.metallib

      # Remove macOS-only nokhwa dep (broken workspace layout breaks vendoring)
      sed -i '/nokhwa-bindings-macos/d' apps/screenpipe-app-tauri/src-tauri/Cargo.toml

      # Create bun sidecar expected by Tauri externalBin config
      ln -s ${bun}/bin/bun apps/screenpipe-app-tauri/src-tauri/bun-x86_64-unknown-linux-gnu

      # Replace source Cargo.lock with our cleaned copy (nokhwa removed)
      cp ${./Cargo.lock} apps/screenpipe-app-tauri/src-tauri/Cargo.lock
    '';

    cargoRoot = "apps/screenpipe-app-tauri/src-tauri";
    buildAndTestSubdir = "apps/screenpipe-app-tauri/src-tauri";

    nativeBuildInputs = [
      pkg-config
      cmake
      makeWrapper
      rustPlatform.bindgenHook
    ];

    buildInputs = [
      # Audio/media
      alsa-lib
      libpulseaudio
      # System
      dbus
      openssl
      openblas
      onnxruntime
      # Display
      libx11
      libxcursor
      libxrandr
      libxi
      libxcb
      libxkbcommon
      wayland
      pipewire
      libGL
      libgbm
      # Tauri/GTK
      gtk3
      webkitgtk_4_1
      libsoup_3
      glib
      glib-networking
      librsvg
      libayatana-appindicator
    ];

    preBuild = ''
      # Fix upstream bug: link name should be "openblas" not "libopenblas"
      local vendor="$NIX_BUILD_TOP/$(stripHash "$cargoDeps")"
      chmod +w "$vendor"/source-git-*/antirez-asr-sys-*/
      substituteInPlace "$vendor"/source-git-*/antirez-asr-sys-*/build.rs \
        --replace-fail 'dylib=libopenblas' 'dylib=openblas'
    '';

    buildNoDefaultFeatures = true;
    buildFeatures = ["custom-protocol" "pulseaudio" "qwen3-asr" "parakeet"];

    env = {
      ORT_LIB_LOCATION = "${lib.getLib onnxruntime}/lib";
      ORT_PREFER_DYNAMIC_LINK = "1";
      NIX_CFLAGS_COMPILE = "-D_GNU_SOURCE";
    };

    doCheck = false;

    postInstall = ''
      # Install Tauri resources (tray icons, etc.) next to the binary
      # Tauri resolves resources relative to the executable's directory
      cp -r $src/apps/screenpipe-app-tauri/src-tauri/assets $out/bin/assets

      wrapProgram $out/bin/screenpipe-app \
        --prefix PATH : ${lib.makeBinPath [tesseract ffmpeg]} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        libayatana-appindicator
        gtk3
        webkitgtk_4_1
        libsoup_3
        glib
      ]} \
        --set GIO_EXTRA_MODULES "${glib-networking}/lib/gio/modules" \
        --set WEBKIT_DISABLE_COMPOSITING_MODE 1
    '';

    passthru = {inherit frontend;};

    meta = {
      description = "Screenpipe desktop app - AI screen and audio recording with local UI";
      homepage = "https://github.com/screenpipe/screenpipe";
      license = lib.licenses.mit;
      maintainers = [];
      mainProgram = "screenpipe-app";
      platforms = lib.platforms.linux;
    };
  }
