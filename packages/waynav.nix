{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  wayland,
  wayland-protocols,
  wayland-scanner,
  libxkbcommon,
  cairo,
}:
stdenv.mkDerivation rec {
  pname = "waynav";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "kovetskiy";
    repo = "waynav";
    tag = version;
    hash = "sha256-gkS5tjSptPniiP2VBQFBfETFOr0ymd/3k5hYsITChAc=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wayland-scanner
  ];

  buildInputs = [
    wayland
    wayland-protocols
    libxkbcommon
    cairo
  ];

  meta = {
    description = "Keyboard-driven mouse navigator for Wayland compositors";
    homepage = "https://github.com/kovetskiy/waynav";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "waynav";
    platforms = lib.platforms.linux;
  };
}
