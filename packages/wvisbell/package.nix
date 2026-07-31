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
  version = "0-unstable-2026-03-23";

  src = fetchFromGitHub {
    owner = "giodamelio";
    repo = "wvisbell";
    rev = "3b5878d824c3a726403bae022e1a63d66dfdde93";
    hash = "sha256-wrXDrlcXcnCOvl19BoTIbVYvxPLE78TRLUsPAgIJGzQ=";
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

  passthru.updatePolicy = "branch";

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
