{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-28";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "e977b503b5b6d5dc7054de23d4f3abdd7927a87d";
    hash = "sha256-TybMtMcZUteSzUx2rvMi1YT2BjnvA/lWvk1YJKWYlZU=";
  };

  cargoHash = "sha256-CGtfCh+2J2TOrS+XTLecs4DZjLqKW6CrH9miX0z4Nyg=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
