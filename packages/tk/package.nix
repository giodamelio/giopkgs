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
    rev = "6ca7de1d7a1f9fae144207e25f13de52b9c6d198";
    hash = "sha256-dxn2U9w1K6k6egqOueNz5UKNcNp7l42ySpZWCR8RpTI=";
  };

  vendorHash = "sha256-yl82YFOAAsfRX8PzTvuNiDIdWe2xT9TebxTRteDAbZQ=";

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
