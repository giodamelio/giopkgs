{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-24";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "93171c1e586574f12e54a8408d841cca38e1b04f";
    hash = "sha256-7s6u+/1InxUer8JtGk2GjEVLaCV830mC8ms0YicvVIw=";
  };

  cargoHash = "sha256-ZstoSf0VEArkhZfTPx/7WEUuAYFSrxEkm5avRT5/bcc=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
