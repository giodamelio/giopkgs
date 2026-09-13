{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-09";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "0f586ab32931e20cf91121f849b3d63a5a7cebd2";
    hash = "sha256-9hcuOWNLckQMLrtWHYGxQIhDQxTPHKV1lElunXDL7Ss=";
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
