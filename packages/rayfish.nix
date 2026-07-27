{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-07-26";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "e07d79593c52271c8110f4f271576daa3d34d8d7";
    hash = "sha256-VaCenoSkwgC8sBvQj8Iidvo0cL3IeGx10N7Yi1iyiys=";
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
