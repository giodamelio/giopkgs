{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-18";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "cf7e500eb58c105485dba4a23c5c9aa6eb866c20";
    hash = "sha256-r2MlpE/wgxTRtK/8oAe2Zu+Xa8DEVgwMCpCte8B9IfU=";
  };

  cargoHash = "sha256-TPKyLzKXayqseMcdQM9+VMbjJo9vXh3zvtUvkpRJld4=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
