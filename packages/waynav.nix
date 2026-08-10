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
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "kovetskiy";
    repo = "waynav";
    tag = version;
    hash = "sha256-Fktfn/xymV5Vnb96xmpRUX/3RUzPjnx85VKJ73aALs4=";
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
