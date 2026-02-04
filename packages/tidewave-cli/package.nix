{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, openssl
, stdenv
, darwin
, applyPatches
}:

let
  src = applyPatches {
    src = fetchFromGitHub {
      owner = "tidewave-ai";
      repo = "tidewave_app";
      rev = "v0.3.3";
      hash = "sha256-+cdvyeFQeJFmYDEB3D8gNE217tvO3wMzhNO2ed0V894=";
    };
    patches = [
      ./remove-src-tauri-from-workspace.patch
      ./remove-tao-patch.patch
      ./remove-tao-patch-cargolock.patch
    ];
  };
in
rustPlatform.buildRustPackage rec {
  pname = "tidewave-cli";
  version = "0.3.3";

  inherit src;

  cargoHash = "sha256-hu4vvDP5aQVHyWkLelmjJh0q9KR8pLZs3HueMOr2BrQ=";

  # Build only the CLI crate from the workspace
  buildAndTestSubdir = "tidewave-cli";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Tidewave CLI";
    homepage = "https://github.com/tidewave-ai/tidewave_app";
    changelog = "https://github.com/tidewave-ai/tidewave_app/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ giodamelio ];
    mainProgram = "tidewave";
  };
}
