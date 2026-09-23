{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-23";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "9f19d875f82acaf51599c64fb2346994bebc62e4";
    hash = "sha256-o5Run5jUIcDFwTRZ1T3rm9/c/33YH3XnoVTq14ZjIU4=";
  };

  cargoHash = "sha256-bcIYlEWxh7v0zgRSEBHC0G/+5mcFRR8bjg8aooO0SNE=";

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
