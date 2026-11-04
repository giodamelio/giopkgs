{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "opentunnel";
  version = "0.6.2";

  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "opentunnel";
    tag = "v${version}";
    hash = "sha256-3F6Dh/IIZMo4vOYmmzuz9y5FXGq01K7GhqvDa0wPpiQ=";
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
