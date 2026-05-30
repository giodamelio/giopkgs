{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
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
}:
rustPlatform.buildRustPackage {
  pname = "screenpipe";
  version = "mcp-v0.18.9";

  src = fetchFromGitHub {
    owner = "screenpipe";
    repo = "screenpipe";
    rev = "ce8374893f1931a83cf1d3dccc4ead634a763074";
    hash = "sha256-3A8WnAN7Q8gWkCGwOq/kP2NG4T1kMhaX72099wz44is=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "accessibility-0.3.0" = "sha256-SBYB62kFmldfangDBtnLqA+T9iUfn+GCCvi0p6E5ou8=";
      "antirez-asr-sys-0.1.0" = "sha256-MtQ9UXDZZouY5+8FCCNKLDJtjlceC8igCGJbXD58z/A=";
      "cidre-0.15.0" = "sha256-u9n/RmUXk4dpEvI+8r6iVNTaSyysi0pe6zNZt4UHh4g=";
      "cpal-0.15.3" = "sha256-2oTXPKJA9WrgL2it2FPKb73SSN3XV2zaMWgzbzUknFo=";
      "ffmpeg-sidecar-2.5.0" = "sha256-WYa0NwJp9872p/thWL/UL8066tb/cdnGvwmjGvKygAU=";
      "hf-hub-0.3.2" = "sha256-hTAdRgJKCN4kTyZXy4SOHPEhBY4/UX+tWJPoUroKLD0=";
      "rusty-tesseract-1.1.10" = "sha256-XT74zGn+DetEBUujHm4Soe2iorQcIoUeZbscTv+64hw=";
      "sck-rs-0.1.0" = "sha256-OZCDLsbMGS0AAo4bMgrnuVaMbEYDGMJ261Pl/NRnEgc=";
      "vad-rs-0.2.0" = "sha256-nkmClKJqj+6vX1EITL0IwR0pqHXoc4/LGJQMgZ3FzGA=";
      "whisper-rs-0.16.0" = "sha256-x2gnbpPHBY6bw8132xEQeh2w7BriSJoxoGQtRhtVTWs=";
    };
  };

  nativeBuildInputs = [
    pkg-config
    cmake
    makeWrapper
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    alsa-lib
    libpulseaudio
    dbus
    openssl
    openblas
    onnxruntime
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
  ];

  preBuild = ''
    # Fix upstream bug: link name should be "openblas" not "libopenblas"
    # (the linker auto-prepends "lib", so "libopenblas" becomes "liblibopenblas")
    local vendor="$NIX_BUILD_TOP/cargo-vendor-dir"
    chmod +w "$vendor"/antirez-asr-sys-*/
    substituteInPlace "$vendor"/antirez-asr-sys-*/build.rs \
      --replace-fail 'dylib=libopenblas' 'dylib=openblas'
  '';

  buildAndTestSubdir = "crates/screenpipe-engine";

  # Default features: qwen3-asr, parakeet (on-device AI speech recognition)
  # Add pulseaudio for Linux audio capture.
  buildFeatures = ["pulseaudio"];

  env = {
    # Point ort to system ONNX Runtime instead of downloading
    ORT_LIB_LOCATION = "${onnxruntime}";
    # antirez-asr-sys uses strdup with -std=c11; expose POSIX/BSD functions
    NIX_CFLAGS_COMPILE = "-D_GNU_SOURCE";
  };

  # Tests need network/audio devices
  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/screenpipe \
      --prefix PATH : ${lib.makeBinPath [tesseract ffmpeg]}
  '';

  meta = {
    description = "AI screen and audio recording tool that captures everything on your desktop";
    homepage = "https://github.com/screenpipe/screenpipe";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "screenpipe";
    platforms = lib.platforms.linux;
  };
}
