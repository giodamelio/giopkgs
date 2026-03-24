{
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  nodejs,
  yarn-berry,
  node-hp-scan-to,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "node-hp-scan-to";
  version = "1.10.0";

  src = fetchFromGitHub {
    owner = "manuc66";
    repo = "node-hp-scan-to";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WAei1bPkwxszc6/oi+u0JXGFV7bBd5ZYDWvUagWAhBg=";
  };

  missingHashes = ./node-hp-scan-to-missing-hashes.json;

  offlineCache = yarn-berry.fetchYarnBerryDeps {
    inherit (finalAttrs) src missingHashes;
    hash = "sha256-GPdd40tYYViGXSFsZQ73yxy4JgUKqLFWMv0N2blFKEo=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    yarn-berry
    yarn-berry.yarnBerryConfigHook
  ];

  installPhase = ''
    runHook preInstall

    yarn install --immutable
    yarn build

    yarn workspaces focus --production

    mkdir -p "$out/lib/node_modules/node-hp-scan-to"
    cp -r dist node_modules package.json "$out/lib/node_modules/node-hp-scan-to"

    makeWrapper "${nodejs}/bin/node" "$out/bin/node-hp-scan-to" \
      --add-flags "$out/lib/node_modules/node-hp-scan-to/dist/index.js"

    runHook postInstall
  '';

  inherit (node-hp-scan-to) meta;
})
