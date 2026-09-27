{
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  makeWrapper,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  node-hp-scan-to,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "node-hp-scan-to";
  version = "1.11.1";

  src = fetchFromGitHub {
    owner = "manuc66";
    repo = "node-hp-scan-to";
    tag = "v${finalAttrs.version}";
    hash = "sha256-waBJIO3syGu6oEIEG+c9JVipuc30GJobUeYLOOh8ZRg=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-ElYF3EpKNu/ZWMHO4lLrKPyCIfAlLssrAepXHgNxjgE=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    pnpm_10
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    pnpm prune --prod

    mkdir -p "$out/lib/node_modules/node-hp-scan-to"
    cp -r dist node_modules package.json "$out/lib/node_modules/node-hp-scan-to"

    makeWrapper "${nodejs}/bin/node" "$out/bin/node-hp-scan-to" \
      --add-flags "$out/lib/node_modules/node-hp-scan-to/dist/index.js"

    runHook postInstall
  '';

  inherit (node-hp-scan-to) meta;
})
