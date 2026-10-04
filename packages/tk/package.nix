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
    rev = "0f00c237f0f099ade10af61409bc4acf9026b316";
    hash = "sha256-3uBKYSGoJLh1R+bgJMqxPJ42Db3OoSXYft3TbBw8lkc=";
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
