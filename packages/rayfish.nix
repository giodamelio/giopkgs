{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-07";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "092ea94e4d9316bb947a85ab04a4e5bce1bc5361";
    hash = "sha256-uROwEs6Z+JZys0H/Vk2jjk5yNU155Xurj7j0cr4mpjo=";
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
