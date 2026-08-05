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
    rev = "b002168b63eb7c540e7ca2257c1951be529f5486";
    hash = "sha256-D7S2JLdp+0pjRQiXK1jJvyq2jQebgIm+CrYcuVP6iJw=";
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
