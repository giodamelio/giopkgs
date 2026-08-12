{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "obsidian-mcp";
  version = "2.3.2";

  src = fetchFromGitHub {
    owner = "lstpsche";
    repo = "obsidian-mcp";
    tag = "v${version}";
    hash = "sha256-Tt7MuhaLHeOKhSudEzPdhiZkLr7ENlhRsixdSueE7/Y=";
  };

  cargoHash = "sha256-DcdVN9P/EyuRt551Kl3kGjz/ZkyFwUQ0GUMo3E3hqqM=";

  meta = {
    description = "MCP server for Obsidian vaults, with direct filesystem access for AI agents";
    homepage = "https://github.com/lstpsche/obsidian-mcp";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "obsidian-mcp";
  };
}
