{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-07-15";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "58217a248aac0287f6c1eade77282b3e0a116cca";
    hash = "sha256-DQY6UdeoBZQtfBTp1DVqn8i+85OlDSzjQObxaAeQMh4=";
  };

  cargoHash = "sha256-dm6gzxhbchgiF+HYb7yYDRINjmsNWu78blNzeCpy3lQ=";

  passthru.updateScript = ./../scripts/update-branch.sh;

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
