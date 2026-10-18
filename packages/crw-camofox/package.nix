{
  lib,
  callPackage,
  fetchFromGitHub,
}:
callPackage ../crw/common.nix {} {
  pname = "crw-camofox";
  # The fork's work lives on feat/camofox-renderer, its default branch; the
  # v1.x tags sit behind the camofox commits, so track the branch tip.
  version = "1.8.1-unstable-2026-10-18";

  src = fetchFromGitHub {
    owner = "adambenhassen";
    repo = "crw-camofox";
    rev = "2519009bdc0702240ff41601752d44428e502ed0";
    hash = "sha256-VImM7eZtZTXTcLTZC88gTXfYemPAgwzjBVmW/cF5xiQ=";
  };

  cargoHash = "sha256-BNInz2+LCdxBVLnnhZr4tv/hn+sUoVFwuiUZ1R0czgk=";

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
