{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  stdenv,
  darwin,
  applyPatches,
}: let
  src = applyPatches {
    src = fetchFromGitHub {
      owner = "tidewave-ai";
      repo = "tidewave_app";
      rev = "v1.1.0";
      hash = "sha256-StSLfM8gVPhfSp/T1C2uyhPqgUreD7N54u6Psh6yZH0=";
    };
    patches = [
      ./remove-src-tauri-from-workspace.patch
      ./remove-tao-patch-cargolock.patch
    ];
    # [patch.crates-io] is the last section of Cargo.toml. Stripping it by
    # section rather than by patch keeps this working across version bumps,
    # which a context patch does not (the workspace version sits in its context).
    postPatch = ''
      sed -i '/^\[patch\.crates-io\]/,$d' Cargo.toml
    '';
  };
in
  rustPlatform.buildRustPackage rec {
    pname = "tidewave-cli";
    version = "1.1.0";

    inherit src;

    cargoHash = "sha256-Q/7dUvje1jrNA20+6y+GEPKERITIW+bTtU8st67ZPag=";

    # Build only the CLI crate from the workspace
    buildAndTestSubdir = "tidewave-cli";

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs =
      [
        openssl
      ]
      ++ lib.optionals stdenv.isDarwin [
        darwin.apple_sdk.frameworks.Security
        darwin.apple_sdk.frameworks.SystemConfiguration
      ];

    meta = {
      description = "Tidewave CLI";
      homepage = "https://github.com/tidewave-ai/tidewave_app";
      changelog = "https://github.com/tidewave-ai/tidewave_app/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [giodamelio];
      mainProgram = "tidewave";
    };
  }
