{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "obsidian-mcp";
  version = "4.1.0";

  src = fetchFromGitHub {
    owner = "lstpsche";
    repo = "obsidian-mcp";
    tag = "v${version}";
    hash = "sha256-p6YubXRNXxf5hee6HDitA2H7wkwJZWXWVTqZqs9XsC8=";
  };

  cargoHash = "sha256-Ii116Wzugjt9EZLWRRNTJnv1HOigb4SREZ/3rrMGe8Y=";

  meta = {
    description = "MCP server for Obsidian vaults, with direct filesystem access for AI agents";
    homepage = "https://github.com/lstpsche/obsidian-mcp";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "obsidian-mcp";
  };
}
