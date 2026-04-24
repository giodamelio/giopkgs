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
    hash = "sha256-aR3xV2LDp6oeccgcFMMdxGM/Ki+EP7ce2hAFN75WI90=";
  };

  # Skip the default yarnBerryConfigHook because yarn 4.14 rejects
  # upstream's lockfile metadata version 8 (it expects 9).
  # We replicate the hook manually with a patched lockfile.
  dontYarnBerryInstallDeps = true;

  nativeBuildInputs = [
    makeWrapper
    nodejs
    yarn-berry
    yarn-berry.yarnBerryConfigHook
  ];

  configurePhase = ''
    runHook preConfigure

    export HOME=$(mktemp -d)

    # Bump lockfile metadata version for yarn 4.14 compatibility
    sed -i 's/^  version: 8$/  version: 9/' yarn.lock

    yarn config set enableTelemetry false
    yarn config set enableGlobalCache false
    yarn config set enableScripts true

    rm -rf ./.yarn/cache
    mkdir -p ./.yarn
    cp -r --reflink=auto $offlineCache/cache ./.yarn/cache
    chmod u+w -R ./.yarn/cache

    export npm_config_nodedir="${nodejs}/include/node"

    YARN_IGNORE_PATH=1 yarn install --mode=skip-build --inline-builds
    patchShebangs node_modules
    YARN_IGNORE_PATH=1 yarn install --inline-builds

    runHook postConfigure
  '';

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
