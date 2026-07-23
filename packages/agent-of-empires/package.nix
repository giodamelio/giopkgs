{
  lib,
  rustPlatform,
  fetchFromGitHub,
  perl,
  stdenv,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "agent-of-empires";
  version = "1.13.1";

  src = fetchFromGitHub {
    owner = "njbrake";
    repo = "agent-of-empires";
    rev = "v${version}";
    hash = "sha256-EJncTgN/+Qc/2O0DBlps2R2naZwOr5Bv091CJVVz/mU=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  # perl is needed to build vendored openssl (git2 dependency)
  nativeBuildInputs = [perl];

  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  # Tests require tmux and a running terminal
  doCheck = false;

  meta = {
    description = "Terminal session manager for AI coding agents";
    homepage = "https://github.com/njbrake/agent-of-empires";
    changelog = "https://github.com/njbrake/agent-of-empires/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "aoe";
  };
}
