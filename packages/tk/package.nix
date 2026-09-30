{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-09-30";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "521f24289bfa1a6637823d03aafd00d54abb2316";
    hash = "sha256-SsOQsgmQMsCC/XTvZC3Gz9C+1EsAsUj3FyEq26BhGyg=";
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
