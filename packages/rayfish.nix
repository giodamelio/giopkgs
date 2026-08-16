{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-16";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "38f0b04649cc26ad2925664735954199837765e3";
    hash = "sha256-TA8kqtHA+qOfcseVwZDtrpU34r0o8E5RU3I+DZUpO78=";
  };

  cargoHash = "sha256-FHp6cCKLEIjz66ISasFnYJANOAlRLrYNdVUMqgagM+U=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
