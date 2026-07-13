{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-07-12";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "2bc6136fbc5a636d77c9f8ee0fccdebcfca08598";
    hash = "sha256-sbK3kW9+oUD+4YMHVs3JlkJe5/NMfZOU1UMxVICTnGY=";
  };

  cargoHash = "sha256-dm6gzxhbchgiF+HYb7yYDRINjmsNWu78blNzeCpy3lQ=";

  passthru.updateScript = ./../scripts/update-branch.sh;

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
