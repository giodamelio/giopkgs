{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-15";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "e7661bbe68e73d3d6f89da89a42162cbfcc05238";
    hash = "sha256-qUEV9bEou4pNv6Ip2I/ivUW/Z0peBV+1mpv7bgTxRyk=";
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
