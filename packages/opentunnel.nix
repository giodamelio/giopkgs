{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "opentunnel";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "opentunnel";
    tag = "v${version}";
    hash = "sha256-6R0kJMl67c0mKq4Pk6aGoa5GKpWXDDZ5kMmU5eUM394=";
  };

  cargoHash = "sha256-RJSkDlzQAtYILuVoX6WBlBYRDB2Rylb94ZjA1oTyCEE=";

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
