{
  lib,
  callPackage,
  fetchFromGitHub,
}:
callPackage ./common.nix {} {
  pname = "crw";
  version = "0.36.0";

  src = fetchFromGitHub {
    owner = "us";
    repo = "crw";
    tag = "v0.35.1";
    hash = "sha256-vR0EVv0HWowBPnJCSk+MU5tLf/a8uDJ/nQQNSkAT+Ig=";
  };

  cargoHash = "sha256-eyb3+Nhfe3YhMisggU5kbQiUN3aDY01W9rbvGdCcsPw=";

  # Same set the published Docker image ships: the CDP renderer ladder plus the
  # in-process Chrome-impersonation HTTP tier.
  buildFeatures = ["cdp" "impersonated"];

  meta = {
    description = "Firecrawl-compatible web scraper, crawler and search API with an MCP server, in Rust";
    homepage = "https://github.com/us/crw";
    license = lib.licenses.agpl3Only;
    maintainers = [];
    mainProgram = "crw";
  };
}
