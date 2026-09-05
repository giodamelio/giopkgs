{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-04";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "73bc440abdfa20d9830beed1901582ba52b0b782";
    hash = "sha256-K6G+Qf3p+iF7Uc5Sf32fpNRyyj743OjlDqFk8+RTtCM=";
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
