{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  wayland,
  wayland-protocols,
  wayland-scanner,
  wlr-protocols,
}:
stdenv.mkDerivation {
  pname = "wvisbell";
  version = "0-unstable-2026-03-22";

  src = fetchFromGitHub {
    owner = "giodamelio";
    repo = "wvisbell";
    rev = "2d07199badf68b4261b34045b106d2256eafca81";
    hash = "sha256-HAbUUTyWlNlUBQ1wP/7f++DmYlhJOPDBRhE5RjoPcc0=";
  };

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
  ];

  buildInputs = [
    wayland
    wayland-protocols
    wlr-protocols
  ];

  passthru.updateScript = ./update.sh;

  installPhase = ''
    runHook preInstall
    install -Dm755 wvisbell $out/bin/wvisbell
    runHook postInstall
  '';

  meta = {
    description = "A port of xvisbell to work with Wayland";
    homepage = "https://github.com/giodamelio/wvisbell";
    license = lib.licenses.unfree;
    maintainers = [];
    mainProgram = "wvisbell";
    platforms = lib.platforms.linux;
  };
}
