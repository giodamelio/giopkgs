{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-13";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "9762365785d6424898f89519348c0f0f3b5dccd4";
    hash = "sha256-LaI6ZFO00bfiCEPKxHFF6RmexOPaIaEMi83EW+jQX9c=";
  };

  cargoHash = "sha256-I+1SVPjsiB6Cqw3TaHqVETWCDB+JFonoVdR/bexUcmE=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
