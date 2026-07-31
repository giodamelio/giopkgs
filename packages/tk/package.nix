{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-02-25";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "d778bb520ee526c314c26f2bb876447e0a19caa5";
    hash = "sha256-unVCgcOyLjh0rt4S6YnK6cPlTjXiYF4mam8EWWyETnc=";
  };

  vendorHash = "sha256-fTbTaSWCvO7H3dS4EVgy4xYFelxAJ/ua39/sp1aDavY=";

  ldflags = [
    "-s"
    "-w"
  ];

  passthru.updatePolicy = "branch";

  meta = {
    description = "Minimal graph-based issue tracker for long-horizon AI agent tasks";
    homepage = "https://github.com/h2oai/tk";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "tk";
  };
}
