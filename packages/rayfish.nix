{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-07-24";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "c50cbab55da33208d09b9a896e51f516810bcc3b";
    hash = "sha256-hjpOECDWElw3CexryoIoPZIUL8OXWTdzqoAbwH07cgo=";
  };

  cargoHash = "sha256-PVyaDNJUPibzfmqU8Sunkpi+ROsfdXufj6BumECWCNI=";

  passthru.updateScript = ./../scripts/update-branch.sh;

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
