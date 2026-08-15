{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-14";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "f54803f59f0b3615127503b52b75b3c5ec2ec1f0";
    hash = "sha256-ZJ0x8hTPKui3LA63MFNiw2EZX4zAZ8i2fSVW7hZUTSQ=";
  };

  cargoHash = "sha256-UqA8M6f83PjuNnqeREYW1C7uBCsPGftQQhvYdajawv0=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
