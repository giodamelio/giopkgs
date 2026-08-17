{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-16";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "fdbcc4b5c2bc20a3fc9d48ca092761ab9125436a";
    hash = "sha256-Vpfl+/igxdLGmBkEiArSigzL/nuYd6rhsWyO+1jHzGA=";
  };

  cargoHash = "sha256-S4WFq8ZHnN5Zm5Fck9q9VLaVjm93+CK5LEjGbPrZpVE=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
