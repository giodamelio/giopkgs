{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-07-08";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "89bd1ca6802672c1acaa2629f937036cb9c83e5d";
    hash = "sha256-uGa1b/pSsguCcOIsTgp3Wryeux2Z+3VVFIjLV9LLYBg=";
  };

  cargoHash = "sha256-dm6gzxhbchgiF+HYb7yYDRINjmsNWu78blNzeCpy3lQ=";

  passthru.updateScript = ./../scripts/update-branch.sh;

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
