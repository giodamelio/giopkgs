{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
}: let
  version = "1.0.12";

  x86_64Hash = "sha256-dzuzyoWpX/IjlJZCGNmfeMrayPwpLiLCdQKuINDOMBo=";
  aarch64Hash = "sha256-IDD3Sfr16FgAX55KB0m+QGOrBUMp1TczbOpIRCtbUrU=";

  images = {
    x86_64-linux = {
      suffix = "";
      hash = x86_64Hash;
    };
    aarch64-linux = {
      suffix = "-arm64";
      hash = aarch64Hash;
    };
  };

  image =
    images.${stdenv.hostPlatform.system}
    or (throw "surrealdb-studio: unsupported platform ${stdenv.hostPlatform.system}");

  src = fetchurl {
    # Upstream publishes no release index — https://download.surrealdb.com/studio/latest.txt
    # is the only version marker, and the filename really does contain a space.
    url = "https://download.surrealdb.com/studio/v${version}/SurrealDB%20Studio-${version}${image.suffix}.AppImage";
    name = "surrealdb-studio-${version}${image.suffix}.AppImage";
    inherit (image) hash;
  };

  contents = appimageTools.extract {
    inherit src version;
    pname = "surrealdb-studio";
  };
in
  appimageTools.wrapType2 {
    pname = "surrealdb-studio";
    inherit version src;

    extraInstallCommands = ''
      install -Dm444 ${contents}/surrealdb-studio.desktop \
        $out/share/applications/surrealdb-studio.desktop
      substituteInPlace $out/share/applications/surrealdb-studio.desktop \
        --replace-fail "Exec=AppRun --no-sandbox" "Exec=surrealdb-studio"
      cp -r ${contents}/usr/share/icons $out/share/icons
    '';

    meta = {
      description = "Visual interface for managing and querying SurrealDB, successor to Surrealist";
      homepage = "https://surrealdb.com/studio";
      license = lib.licenses.unfree;
      maintainers = [];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = lib.attrNames images;
      mainProgram = "surrealdb-studio";
    };
  }
