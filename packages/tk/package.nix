{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-10-18";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "3c9156c5e6798c3f79ea8d188c50801d3aa3efb8";
    hash = "sha256-WVjOei6hUS6pizThx6zatBLirjccxMmBQ9/sC5V7vLM=";
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
