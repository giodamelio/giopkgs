{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-09-24";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "ef8c9a717cb81fb97e19de965df5fc9d0622a17e";
    hash = "sha256-bzpHJ4XuW9ipETVXQNCc5Bz2EXz+rEZLTwEeojBSI3o=";
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
