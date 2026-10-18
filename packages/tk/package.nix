{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-10-17";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "5ac292024a76632c4debeec84b29d978a31ae87c";
    hash = "sha256-S0eAtjjCS77EATpfIKH4qEh6APaZwA4AizxKqpyVuX0=";
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
