{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-23";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "fe8266ee8226f2b8f3bf0ad4ca3220b3fd849f4f";
    hash = "sha256-t4y95ttuOJaqRap9bMCS4vAttWSUoTmx6DzHx16ys4o=";
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
