{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-04";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "721797aed1cdd4d0cebe95e3fb7f0e2582b743c1";
    hash = "sha256-MEVV8fwTGo9CVnFbilFGgz7iy5Bu5bMna7fRLYyA308=";
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
