{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-10-15";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "b0720d89805ea9347f99586178197428ab5486ac";
    hash = "sha256-7NtUysV1uHms/PNrLZFkynZOPHbnr88yWXrlsjavDzg=";
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
