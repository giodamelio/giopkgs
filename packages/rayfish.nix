{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-07-17";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "840c3be7e67f7e9cbcebb99a0f0ff69bc7c82a81";
    hash = "sha256-szodzJvn4NbcjjVZSniuehr74PUiNe8dn3NQ2L/mUN4=";
  };

  cargoHash = "sha256-PVyaDNJUPibzfmqU8Sunkpi+ROsfdXufj6BumECWCNI=";

  passthru.updateScript = ./../scripts/update-branch.sh;

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
