{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-07-08";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "5ec651b7b71fda3569e337ca37af7ebc9cf95617";
    hash = "sha256-vmGG4adu1bHrABO9pfT847hbTiVFAakZSfTwwfa7oYE=";
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
