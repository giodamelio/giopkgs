{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "0db1455302331f055cbd0937098e648a02341675";
    hash = "sha256-c19vHF2YSJIBHWsm0u/Vj3UTERmKilQmzP/FXE5xI6Y=";
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
