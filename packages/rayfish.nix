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
    rev = "5c7564c25f995920c24bd0ad0324cd369e9160a9";
    hash = "sha256-QQbxTjZRySpgYKmJOjd56rjmOp7kbIEOYzJa4wlq3KA=";
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
