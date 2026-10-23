{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "opentunnel";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "opentunnel";
    tag = "v${version}";
    hash = "sha256-WB9pwiuimWs7YFDZEj4WQaC8lbPYt23L/s1oBvHBafI=";
  };

  cargoHash = "sha256-k51CPC0cesNUc+tN2DowGaR4Kx0VPRIXpL6RQra3pdQ=";

  cargoBuildFlags = ["-p" "opentunnel-cli"];
  cargoTestFlags = ["-p" "opentunnel-cli" "-p" "opentunnel"];

  meta = {
    description = "Blind TLS tunnel that exposes local ports under a unique opentunnel.xyz hostname";
    homepage = "https://github.com/anomalyco/opentunnel";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "opentunnel";
  };
}
