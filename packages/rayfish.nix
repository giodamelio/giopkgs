{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-02";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "971c95255e325e679ee248d5944d00c8417f5a77";
    hash = "sha256-eZ9wl49eWtrBALSfzKbMIjRec9paaWSiQ8DAD7Owr0Y=";
  };

  cargoHash = "sha256-eSOaDmL/Mat/LNBoJA8jyGtesIiUYXJWDVQV1vfyKrQ=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
