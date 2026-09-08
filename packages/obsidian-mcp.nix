{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "obsidian-mcp";
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "lstpsche";
    repo = "obsidian-mcp";
    tag = "v${version}";
    hash = "sha256-yXsB/k3OFEBUOqyhCQ2WFf5F06IoG8uzJ3eCIJfXJIg=";
  };

  cargoHash = "sha256-7Fxv/ecBZ8ZkkgaUbjC8zebX2HldukqHfYCvdY9Zec0=";

  meta = {
    description = "MCP server for Obsidian vaults, with direct filesystem access for AI agents";
    homepage = "https://github.com/lstpsche/obsidian-mcp";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "obsidian-mcp";
  };
}
