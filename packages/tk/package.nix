{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tk";
  version = "0-unstable-2026-09-18";

  src = fetchFromGitHub {
    owner = "h2oai";
    repo = "tk";
    rev = "1ed04592597bec8ac7a07e6f6bc2adef020c9ac7";
    hash = "sha256-ToxtkUcuy+8/6UdowXfzXTxHA79iqpQ3YnZLfPZVqvo=";
  };

  vendorHash = "sha256-fTbTaSWCvO7H3dS4EVgy4xYFelxAJ/ua39/sp1aDavY=";

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
