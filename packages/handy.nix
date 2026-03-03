{
  pkgs,
  lib,
  ...
}:
pkgs.stdenv.mkDerivation rec {
  pname = "handy";
  version = "0.7.9";

  src = pkgs.fetchurl {
    url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_amd64.AppImage";
    hash = "sha256-iSibRpme8xJfumhjJ2LzkrtFwV8j9nHajMnBygBFLz4=";
  };

  nativeBuildInputs = [pkgs.makeWrapper];

  appimage = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    extraPkgs = p:
      with p; [
        alsa-lib
        wtype # For Handy to type into Wayland
        wireplumber # For muting system audio while recording
      ];
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    makeWrapper ${appimage}/bin/${pname} $out/bin/${pname} \
      --set WEBKIT_DISABLE_DMABUF_RENDERER 1

    runHook postInstall
  '';

  meta = with lib; {
    description = "A handy AI assistant";
    homepage = "https://github.com/cjpais/Handy";
    license = licenses.mit;
    platforms = ["x86_64-linux"];
    maintainers = with lib.maintainers; [giodamelio];
    mainProgram = "handy";
  };
}
