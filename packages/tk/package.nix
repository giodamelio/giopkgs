{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-10-30";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "301f35452825e92b279b31402a8096cd6a1f5c94";
    hash = "sha256-BK/EPWLH3NMrO9NmZb2ggTObVgfAcVvhSHzvyCgCDrM=";
  };

  vendorHash = "sha256-dUswAHBnOusQsYxI6ImYmGRj1HdaVye+JndfofeYLjs=";

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
