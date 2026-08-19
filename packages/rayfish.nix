{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-18";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "07cb7b8006472cc8f220998c203eeb625609ddf1";
    hash = "sha256-eFOMo4yAP/rbDWsv9YOjy46HPiW3q9Z0VyiCQ+/2K58=";
  };

  cargoHash = "sha256-S4WFq8ZHnN5Zm5Fck9q9VLaVjm93+CK5LEjGbPrZpVE=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
