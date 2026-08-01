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
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "kovetskiy";
    repo = "waynav";
    tag = version;
    hash = "sha256-oEfHiAP2OSqxIPqeXNa7gUe0ZSXex9V6rnXpliByaWc=";
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
