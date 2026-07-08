{
  lib,
  stdenv,
  fetchFromGitHub,
  zlib,
}:
stdenv.mkDerivation rec {
  pname = "codebase-memory-mcp";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "DeusData";
    repo = "codebase-memory-mcp";
    tag = "v${version}";
    hash = "sha256-4P7PVz6vLbokrrKv1QzsWJ3SNULpwyufcXmloHJUVqQ=";
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
