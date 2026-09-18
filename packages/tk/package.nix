{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-09-17";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "1670899f2627ab5deefd12f08cd543fa5ac5ce7a";
    hash = "sha256-PSIbswG6L6x+AU3xGFJF6t07FpiKolqZqMu3RlkRJYg=";
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
