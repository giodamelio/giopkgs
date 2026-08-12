{
  lib,
  python3,
  fetchFromGitHub,
}: let
  # mnemosyne's MCP server needs mcp >= 2.0, which nixpkgs does not carry yet.
  # 2.0 split the wire types into a separate mcp-types distribution.
  mcpVersion = "2.0.0";
  mcpSrc = fetchFromGitHub {
    owner = "modelcontextprotocol";
    repo = "python-sdk";
    tag = "v${mcpVersion}";
    hash = "sha256-baeceVB9PC+f3vQO1AaDHflOJ7oD7u7ylXUkVvusT/o=";
  };

  python = python3.override {
    self = python;
    packageOverrides = final: prev: {
      mcp-types = prev.buildPythonPackage {
        pname = "mcp-types";
        version = mcpVersion;
        pyproject = true;

        src = mcpSrc;
        sourceRoot = "${mcpSrc.name}/src/mcp-types";

        build-system = with prev; [hatchling uv-dynamic-versioning];

        dependencies = with prev; [pydantic typing-extensions];

        doCheck = false;

        pythonImportsCheck = ["mcp_types"];

        meta = {
          description = "Model Context Protocol wire types";
          homepage = "https://github.com/modelcontextprotocol/python-sdk";
          license = lib.licenses.mit;
        };
      };

      mcp = prev.mcp.overridePythonAttrs (old: {
        version = mcpVersion;
        src = mcpSrc;

        dependencies = with prev; [
          anyio
          httpx2
          jsonschema
          final.mcp-types
          opentelemetry-api
          pydantic
          pyjwt
          cryptography
          python-multipart
          sse-starlette
          starlette
          typing-extensions
          typing-inspection
          uvicorn
        ];

        doCheck = false;

        meta = old.meta // {changelog = "https://github.com/modelcontextprotocol/python-sdk/releases/tag/v${mcpVersion}";};
      });
    };
  };
in
  python.pkgs.buildPythonApplication rec {
    pname = "mnemosyne";
    version = "3.15.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "mnemosyne-oss";
      repo = "mnemosyne";
      tag = "v${version}";
      hash = "sha256-Lk0Xx+q266wNBpHrBJUVu98OFkGRN3GXmG2ZK3U1h7w=";
    };

    build-system = [python.pkgs.setuptools];

    dependencies = with python.pkgs; [
      pyyaml
      # [mcp] extra, for `mnemosyne mcp`
      mcp
      anyio
      # [sync] extra, for `mnemosyne sync`
      cryptography
    ];

    doCheck = false;

    meta = {
      description = "Zero-cloud SQLite-backed memory layer for AI agents";
      homepage = "https://github.com/mnemosyne-oss/mnemosyne";
      license = lib.licenses.mit;
      maintainers = [];
      mainProgram = "mnemosyne";
    };
  }
