{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
}:
rustPlatform.buildRustPackage rec {
  pname = "docsrs-mcp";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "dmvk";
    repo = "docsrs-mcp";
    tag = "v${version}";
    hash = "sha256-5QoXTQ2QWDb+f6KCWgC7qTrUAobz9VlgRif3BfmvNmQ=";
  };

  cargoHash = "sha256-2TwNuXzqDr5H87RJyu4/0OSaGr3a6WnleCUTou9U2Ck=";

  nativeBuildInputs = [pkg-config];
  buildInputs = [openssl];

  meta = {
    description = "MCP server providing access to Rust crate documentation from docs.rs";
    homepage = "https://github.com/dmvk/docsrs-mcp";
    license = lib.licenses.asl20;
    maintainers = [];
    mainProgram = "docsrs-mcp";
  };
}
