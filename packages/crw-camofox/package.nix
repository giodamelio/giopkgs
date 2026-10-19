{
  lib,
  callPackage,
  fetchFromGitHub,
}:
callPackage ../crw/common.nix {} {
  pname = "crw-camofox";
  # The fork's work lives on feat/camofox-renderer, its default branch; the
  # v1.x tags sit behind the camofox commits, so track the branch tip.
  version = "1.8.2-unstable-2026-10-18";

  src = fetchFromGitHub {
    owner = "adambenhassen";
    repo = "crw-camofox";
    rev = "a48e270194ef28b782d00d67a1e14454d4f2d5f1";
    hash = "sha256-r5gRxpRSl26/ViDzrxTqYjKmKzZVkbUKgUtsQJDQAU4=";
  };

  cargoHash = "sha256-GXwPykhpw0wONHO3a7oN0EI2hU0CeEYEcWI89mDvfDI=";

  # `camofox` is what this fork adds over upstream: a Camoufox-backed renderer
  # tier that also backs /v1/search, replacing upstream's SearXNG sidecar.
  buildFeatures = ["cdp" "camofox" "impersonated"];

  meta = {
    description = "Fork of crw whose renderer ladder ends in Camofox (Camoufox) instead of Chrome";
    homepage = "https://github.com/adambenhassen/crw-camofox";
    license = lib.licenses.agpl3Only;
    maintainers = [];
    mainProgram = "crw";
  };
}
