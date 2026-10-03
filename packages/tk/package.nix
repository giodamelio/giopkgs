{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-10-03";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "96fb76fff7a83537c01fd96024dc2a6588e46595";
    hash = "sha256-G9w/OGqhnJZYwpULHLvXKARejZI90rxN0JeyQ6XIttQ=";
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
