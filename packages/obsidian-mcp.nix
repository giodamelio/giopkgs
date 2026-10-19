{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "obsidian-mcp";
  version = "3.2.0";

  src = fetchFromGitHub {
    owner = "lstpsche";
    repo = "obsidian-mcp";
    tag = "v${version}";
    hash = "sha256-EOBX6HLkkT7BUFC9ES/oyTJ0Re02EdeU1uZ/xk2mbd8=";
  };

  cargoHash = "sha256-bkb9Ad74IVUoVtYBTf/L+K/mVHNkIutu6FQ60P4XjbQ=";

  meta = {
    description = "MCP server for Obsidian vaults, with direct filesystem access for AI agents";
    homepage = "https://github.com/lstpsche/obsidian-mcp";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "obsidian-mcp";
  };
}
