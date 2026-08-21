{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "obsidian-mcp";
  version = "2.5.0";

  src = fetchFromGitHub {
    owner = "lstpsche";
    repo = "obsidian-mcp";
    tag = "v${version}";
    hash = "sha256-aTC0KkuVrwzyTX04ffvpG1rtyHXmYqJLzCccntzVpz8=";
  };

  cargoHash = "sha256-HdC1m3Jtt4kOonLHfScCLLF6n5gPKglUOuJEf/i1cLs=";

  meta = {
    description = "MCP server for Obsidian vaults, with direct filesystem access for AI agents";
    homepage = "https://github.com/lstpsche/obsidian-mcp";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "obsidian-mcp";
  };
}
