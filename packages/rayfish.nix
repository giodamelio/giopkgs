{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-01";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "bd48d8fdc28e152ca0402152fb01d5c02ae26e8e";
    hash = "sha256-lXDPTZ1KzvGJDwscVtCudAnC9AqDinqZZaIdmWPJvTs=";
  };

  cargoHash = "sha256-4du+r2lC5FJ9nQGGxRKMT1ENMkYBplZasboLULp2yOM=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
