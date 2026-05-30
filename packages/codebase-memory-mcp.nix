{
  lib,
  stdenv,
  fetchFromGitHub,
  zlib,
}:
stdenv.mkDerivation rec {
  pname = "codebase-memory-mcp";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "DeusData";
    repo = "codebase-memory-mcp";
    tag = "v${version}";
    hash = "sha256-In99dYwqF9BZy3HD9/7bOdO3D3OmgtXYAWGdfqnspPU=";
  };

  buildInputs = [zlib];

  makefile = "Makefile.cbm";
  makeFlags = ["cbm"];
  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp build/c/codebase-memory-mcp $out/bin/
    runHook postInstall
  '';

  meta = {
    description = "High-performance code intelligence MCP server that builds a persistent knowledge graph from source code";
    homepage = "https://github.com/DeusData/codebase-memory-mcp";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "codebase-memory-mcp";
  };
}
