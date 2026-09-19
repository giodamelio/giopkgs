{
  lib,
  callPackage,
  fetchFromGitHub,
}:
callPackage ../crw/common.nix {} {
  pname = "crw-camofox";
  # The fork's work lives on feat/camofox-renderer, its default branch; the
  # v1.x tags sit behind the camofox commits, so track the branch tip.
  version = "1.5.0-unstable-2026-09-16";

  src = fetchFromGitHub {
    owner = "adambenhassen";
    repo = "crw-camofox";
    rev = "796d8c9fa695165867ba8a778f39c9e575e8e154";
    hash = "sha256-LuxBtGy8aKcYeQPR7ptiZPLj3vlea6PD04r4zZiOaI0=";
  };

  cargoHash = "sha256-srgQx/Vr3vVKY3d3v5wuJRkXsg0KQ4buREpQyDhOkh0=";

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
