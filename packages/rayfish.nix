{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-25";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "1e3a0ec28825e4065f5f0e682dc6a18f25d423f1";
    hash = "sha256-a5Rm+gTk0hlPD15BfDE0hbfBGKnSq7u0ZsqCFb5ZBVc=";
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
