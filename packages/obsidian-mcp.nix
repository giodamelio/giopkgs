{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "obsidian-mcp";
  version = "5.1.1";

  src = fetchFromGitHub {
    owner = "lstpsche";
    repo = "obsidian-mcp";
    tag = "v${version}";
    hash = "sha256-0yXJVPbxbY1VfRMfGuT0Nqtpeq6D10eVajEq0Kj+GOA=";
  };

  cargoHash = "sha256-1Z9Bc8NophCXfpUXdpm+FAmuKXvswlaqAL3MJIHD99c=";

  meta = {
    description = "MCP server for Obsidian vaults, with direct filesystem access for AI agents";
    homepage = "https://github.com/lstpsche/obsidian-mcp";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "obsidian-mcp";
  };
}
