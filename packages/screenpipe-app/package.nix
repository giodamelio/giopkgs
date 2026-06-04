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
  version = "app-v2.5.4";
  rev = "ce8374893f1931a83cf1d3dccc4ead634a763074";

  src = fetchFromGitHub {
    owner = "screenpipe";
    repo = "screenpipe";
    inherit rev;
    hash = "sha256-3A8WnAN7Q8gWkCGwOq/kP2NG4T1kMhaX72099wz44is=";
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

      # Build Next.js static export
      bun node_modules/next/dist/bin/next build
    '';

    installPhase = ''
      cp -r out $out
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-27D4e7/ZfC3jZXwIgpkqQG4nCjPDWh8StqKgcc21sI8=";
  };
in
  rustPlatform.buildRustPackage {
    pname = "screenpipe-app";
    inherit version src;

    cargoLock = {
      lockFile = ./Cargo.lock;
      outputHashes = {
        # Shared with CLI
        "accessibility-0.3.0" = "sha256-SBYB62kFmldfangDBtnLqA+T9iUfn+GCCvi0p6E5ou8=";
        "antirez-asr-sys-0.1.0" = "sha256-MtQ9UXDZZouY5+8FCCNKLDJtjlceC8igCGJbXD58z/A=";
        "cidre-0.15.0" = "sha256-u9n/RmUXk4dpEvI+8r6iVNTaSyysi0pe6zNZt4UHh4g=";
        "cpal-0.15.3" = "sha256-2oTXPKJA9WrgL2it2FPKb73SSN3XV2zaMWgzbzUknFo=";
        "hf-hub-0.3.2" = "sha256-hTAdRgJKCN4kTyZXy4SOHPEhBY4/UX+tWJPoUroKLD0=";
        "rusty-tesseract-1.1.10" = "sha256-XT74zGn+DetEBUujHm4Soe2iorQcIoUeZbscTv+64hw=";
        "sck-rs-0.1.0" = "sha256-OZCDLsbMGS0AAo4bMgrnuVaMbEYDGMJ261Pl/NRnEgc=";
        "vad-rs-0.2.0" = "sha256-nkmClKJqj+6vX1EITL0IwR0pqHXoc4/LGJQMgZ3FzGA=";
        "whisper-rs-0.16.0" = "sha256-x2gnbpPHBY6bw8132xEQeh2w7BriSJoxoGQtRhtVTWs=";
        # App-specific (different commit from CLI)
        "ffmpeg-sidecar-2.3.0" = "sha256-kOd/zWlxC/Km1pDErMdzeo3h1wJ7WOYFKJNj6ayMjdA=";
        # App-only deps
        "fix-path-env-0.0.0" = "sha256-UygkxJZoiJlsgp8PLf1zaSVsJZx1GGdQyTXqaFv3oGk=";
        "tauri-nspanel-2.0.1" = "sha256-pQgv/Lkc9yE+DSv+MdOV1NZRj2nkMhAm+Wn41qvdvvE=";
        "windows-icons-0.1.1" = "sha256-Lrw9W71ihFYsC4EHThfQdmeJdEW3dE71NiNrFKZp7Ks=";
      };
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
      local vendor="$NIX_BUILD_TOP/cargo-vendor-dir"
      chmod +w "$vendor"/antirez-asr-sys-*/
      substituteInPlace "$vendor"/antirez-asr-sys-*/build.rs \
        --replace-fail 'dylib=libopenblas' 'dylib=openblas'
    '';

    buildNoDefaultFeatures = true;
    buildFeatures = ["custom-protocol" "pulseaudio" "qwen3-asr" "parakeet"];

    env = {
      ORT_LIB_LOCATION = "${onnxruntime}";
      NIX_CFLAGS_COMPILE = "-D_GNU_SOURCE";
    };

    doCheck = false;

    postInstall = ''
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

    meta = {
      description = "Screenpipe desktop app - AI screen and audio recording with local UI";
      homepage = "https://github.com/screenpipe/screenpipe";
      license = lib.licenses.mit;
      maintainers = [];
      mainProgram = "screenpipe-app";
      platforms = lib.platforms.linux;
    };
  }
