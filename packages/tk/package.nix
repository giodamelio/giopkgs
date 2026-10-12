{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-10-12";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "365be9d19515b18c9e5910e2f0b3444c6a10b012";
    hash = "sha256-/Yr/ln9hHgKWi4NqYakwp1vRQPQ4EwzrOUY4TSMBCTk=";
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
