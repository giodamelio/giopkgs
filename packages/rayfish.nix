{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-19";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "8f3b4db6725207393da198340b6f7ce7ce0aa0f1";
    hash = "sha256-qPRpVNCJ3F/c1lFAFaK+0sXmWfV/lNrG8efrDHWOIy4=";
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
