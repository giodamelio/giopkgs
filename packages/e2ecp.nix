{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
}: let
  version = "3.2.0";

  src = fetchFromGitHub {
    owner = "schollz";
    repo = "e2ecp";
    tag = "v${version}";
    hash = "sha256-4eictkYJ5IwKifa+K3Yn7O0LtAWU5dGRGzVyDaq+72g=";
  };

  webAssets = buildNpmPackage {
    pname = "e2ecp-web";
    inherit version src;
    sourceRoot = "${src.name}/web";
    npmDepsHash = "sha256-PAzg+iX6u0St8Ej/Mi0/XcOpSqEKDWJI6YDo6p3RLks=";
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist/* $out/
      runHook postInstall
    '';
  };
in
  buildGoModule {
    pname = "e2ecp";
    inherit version src;

    vendorHash = "sha256-nJLBGskdQiX8tIc+ScaSCNH7UBKnCsQ8MS91Kn8hbhQ=";

    preBuild = ''
      mkdir -p web/dist
      cp -r ${webAssets}/* web/dist/
      touch web/dist/.keep
    '';

    ldflags = [
      "-s"
      "-w"
    ];

    # Tests require network access and a running server
    doCheck = false;

    meta = {
      description = "End-to-end encrypted file transfer tool";
      homepage = "https://github.com/schollz/e2ecp";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [];
      mainProgram = "e2ecp";
    };
  }
