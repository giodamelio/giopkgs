{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-07-25";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "24b6a0332c96666b8a6dfff2fc444e7b61427264";
    hash = "sha256-BJrK+KMaOCNklTed4eQBUt2DNLcIfnKEU48Cz1BRtv0=";
  };

  cargoHash = "sha256-I+1SVPjsiB6Cqw3TaHqVETWCDB+JFonoVdR/bexUcmE=";

  passthru.updateScript = ./../scripts/update-branch.sh;

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
