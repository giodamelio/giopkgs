{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-06";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "bef90715928ca20f6bf1fcefca7a0ed9ada2982c";
    hash = "sha256-8L4uEamD2OkGMeac4UCI1lGRkEHZaXYNUO1QX/ITid8=";
  };

  cargoHash = "sha256-Hzk95/ZqLsf97kQHkPElDJJYLIIpM6OlIVn1yzs9vIo=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
