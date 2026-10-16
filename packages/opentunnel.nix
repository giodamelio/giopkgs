{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "opentunnel";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "opentunnel";
    tag = "v${version}";
    hash = "sha256-tDrfQXE1JVrYqo/lYmxXOKDVO+LnkevJnHsVUQGLTno=";
  };

  cargoHash = "sha256-2bnhoktH2qbtHpR6Kh6ag0qLYe3W1vESPCx8L3urPl4=";

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
