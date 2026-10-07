{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-10-06";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "563626266323616f5bc488630b3cdc41320a6ff3";
    hash = "sha256-oBx9VjQOuKovqZ+X7JPAPVQyLxZzvgeUt5QCGwEEWXw=";
  };

  vendorHash = "sha256-ao08hQZ6IpM4JUzBfQ6dMUFTYu14DQHJvI0HCBgG6PE=";

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
