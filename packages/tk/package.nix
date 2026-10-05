{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-10-05";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "ab691f2fc0b1844ba1550e8804e02168d02c22fb";
    hash = "sha256-z044GYDvHOgvV82JF+oW+uaKmqCro23gmmI05t1Aj6I=";
  };

  vendorHash = "sha256-Hdr6kDruf5+JgIDhe0GdXC2WrA+WYtDr0GsgSWOBMYg=";

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
