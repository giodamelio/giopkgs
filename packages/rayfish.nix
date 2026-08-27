{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-27";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "873cd6a586f42bedfde92aaf91dfd92e94e2974e";
    hash = "sha256-KEC6WI1CgsFG8SFepptVv2v3wiff1lwjU+Tn7zBzJCM=";
  };

  cargoHash = "sha256-CGtfCh+2J2TOrS+XTLecs4DZjLqKW6CrH9miX0z4Nyg=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
