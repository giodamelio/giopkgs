{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "opentunnel";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "opentunnel";
    tag = "v${version}";
    hash = "sha256-BraKOWlJVGbqPYV+EOiIklr7NM4ULuRCtUSzgwPt6Oc=";
  };

  cargoHash = "sha256-uXPn4jmxp1fhZN4K1a6rchQynQnht2CPrUEU6mTLqkM=";

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
