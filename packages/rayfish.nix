{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-21";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "a52a0f6f5defca12d7e9202c2a35e4994e271d1e";
    hash = "sha256-z4he9hlSH0TQk3DcgRdT6it3GbS3slbyMlAFxrlUmO4=";
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
