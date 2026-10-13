{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-10-13";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "71a76c2e674498fed815b6dac8c21a8e9a50c0d5";
    hash = "sha256-eQw+3H2XIj9BKy63c/YQk+e0vl9mfqzPOofnWE+HSXQ=";
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
