{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-22";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "7352bbfa24f33429387c8aceb49d35ee9ea8c2b3";
    hash = "sha256-myabqpkqu7eNNGTjSrcR8ePNG+O2wp2UN1zQ58EhrHU=";
  };

  cargoHash = "sha256-1qEHZVBWJznjkZc066jdaU60FABcjZmz/Tl/HMo82jc=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
