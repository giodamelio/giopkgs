{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "anytype-mcp";
  version = "2.0.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@anyproto/anytype-mcp/-/anytype-mcp-${finalAttrs.version}.tgz";
    hash = "sha256-BDYhxtIPP3aZzr7Y/WzfP8KuBkWQLd0N6hC+1/neME8=";
  };

  nativeBuildInputs = [makeWrapper];

  # Upstream publishes bin/cli.mjs as a self-contained esbuild bundle — no bare
  # imports survive it, so there is no npm closure to build. Upstream ships only
  # a bun.lock, which nixpkgs has no builder for.
  installPhase = ''
    runHook preInstall

    install -Dm444 bin/cli.mjs "$out/lib/anytype-mcp/cli.mjs"
    makeWrapper ${lib.getExe nodejs} "$out/bin/anytype-mcp" \
      --add-flags "$out/lib/anytype-mcp/cli.mjs"

    runHook postInstall
  '';

  meta = {
    description = "MCP server exposing the Anytype API to AI assistants";
    homepage = "https://github.com/anyproto/anytype-mcp";
    license = lib.licenses.mit;
    maintainers = [];
    platforms = lib.platforms.all;
    mainProgram = "anytype-mcp";
  };
})
