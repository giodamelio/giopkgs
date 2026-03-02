# Fixed-output derivation for oh-my-pi node_modules
# Runs bun install and canonicalizes output for deterministic hashing
{
  lib,
  stdenvNoCC,
  bun,
  cacert,
  ompHashes ? builtins.fromJSON (builtins.readFile ./hashes.json),
  hash ? ompHashes.nodeModulesHashes.${stdenvNoCC.hostPlatform.system},
}:
let
  platform = stdenvNoCC.hostPlatform;
  bunCpu = if platform.isAarch64 then "arm64" else "x64";
  bunOs = if platform.isLinux then "linux" else "darwin";
in
stdenvNoCC.mkDerivation {
  pname = "omp-node_modules";
  version = ompHashes.version;

  src = builtins.fetchTarball {
    url = "https://github.com/${ompHashes.owner}/${ompHashes.repo}/archive/${ompHashes.rev}.tar.gz";
    sha256 = ompHashes.srcHash;
  };

  impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
    "GIT_PROXY_COMMAND"
    "SOCKS_SERVER"
  ];

  nativeBuildInputs = [ bun cacert ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt

    bun install \
      --cpu="${bunCpu}" \
      --os="${bunOs}" \
      --frozen-lockfile \
      --ignore-scripts \
      --no-progress

    bun --bun ${./scripts/canonicalize-node-modules.ts}
    bun --bun ${./scripts/normalize-bun-binaries.ts}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    find . -type d -name node_modules -exec cp -R --parents {} $out \;

    runHook postInstall
  '';

  dontFixup = true;

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = hash;

  meta.platforms = [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
