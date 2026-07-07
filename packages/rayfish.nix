{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "2026-07-06-87e2019";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "87e2019dc5c209871f945313f4371561add6fba4";
    hash = "sha256-6pVDsHN66RYG5wXdLYGCsHzsVDEY+JU4pXOY6+0VCIo=";
  };

  cargoHash = "sha256-JYsFvzpdn41Zfe4UsEqPWZ3xp1/JKGe1ewtTOD6aKT0=";

  passthru.updateScript = ./../scripts/update-branch.sh;

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
