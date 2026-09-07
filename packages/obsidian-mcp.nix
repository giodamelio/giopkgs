{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "obsidian-mcp";
  version = "2.5.1";

  src = fetchFromGitHub {
    owner = "lstpsche";
    repo = "obsidian-mcp";
    tag = "v${version}";
    hash = "sha256-8uU2i4VxVS1fe7SLQZ8sTnlq83wbcmNQksZYgx0xD9s=";
  };

  cargoHash = "sha256-Ci5vAWVWbHXUZvOpwhdf1/tJrDi4WiV9gpM+dDdSaKo=";

  meta = {
    description = "MCP server for Obsidian vaults, with direct filesystem access for AI agents";
    homepage = "https://github.com/lstpsche/obsidian-mcp";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "obsidian-mcp";
  };
}
