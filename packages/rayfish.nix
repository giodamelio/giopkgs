{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-25";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "87d24f6766edae0a4fee592754be842916cf1afa";
    hash = "sha256-LU2qL5k/mWzsqonaLdejvHDCD4eb/83Hgt2E/y8VWSQ=";
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
