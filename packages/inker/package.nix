{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  buildNpmPackage,
  fetchNpmDeps,
  runCommand,
  autoPatchelfHook,
  nodejs,
  openssl,
  chromium,
}: let
  pname = "inker";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "usetrmnl";
    repo = "inker";
    tag = version;
    hash = "sha256-dQoNf3dMdVxcmDYxWOmoyOKDTXFMarxLLh452Vy/ITo=";
  };

  # The upstream package-lock.json files are stale (the project's real lockfile
  # is bun.lock). We vendor freshly regenerated npm lockfiles next to this
  # derivation and splice them into the source tree at build time. update.sh
  # regenerates them.
  lockDir = lock:
    runCommand "inker-lock" {} ''
      mkdir -p $out
      cp ${lock} $out/package-lock.json
    '';

  # Prisma ships its query/schema engines as separately-downloaded binaries,
  # version-locked to the client via a commit hash. The npm postinstall that
  # normally fetches them cannot run in the sandbox, and nixpkgs' prisma-engines
  # is a different major version, so we pin the matching binaries by hand.
  # Commit comes from @prisma/engines-version in backend-package-lock.json.
  prismaEnginesCommit = "605197351a3c8bdd595af2d2a9bc3025bca48ea2";
  prismaEngineUrl = engine: "https://binaries.prisma.sh/all_commits/${prismaEnginesCommit}/debian-openssl-3.0.x/${engine}.gz";
  prisma-engines = stdenv.mkDerivation {
    pname = "inker-prisma-engines";
    version = prismaEnginesCommit;

    dontUnpack = true;

    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [openssl stdenv.cc.cc.lib];

    libquerySrc = fetchurl {
      url = prismaEngineUrl "libquery_engine.so.node";
      hash = "sha256-ETwMIJMjMgZmjH6QGD7GVwYYlyx9mo2ydEeunFViCjQ=";
    };
    schemaSrc = fetchurl {
      url = prismaEngineUrl "schema-engine";
      hash = "sha256-rzzzPHOpUM3GJvkhU08lQ7rNspdq3RKxMRRW9YZtvhU=";
    };
    querySrc = fetchurl {
      url = prismaEngineUrl "query-engine";
      hash = "sha256-Pl/YpYu326qqpbVfczM5RxB8iWXZlewG9vToqzSPIQo=";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib $out/bin
      gzip -dc $libquerySrc > $out/lib/libquery_engine.so.node
      gzip -dc $schemaSrc   > $out/bin/schema-engine
      gzip -dc $querySrc    > $out/bin/query-engine
      chmod +x $out/bin/* $out/lib/*
      runHook postInstall
    '';
  };

  prismaEnv = {
    PRISMA_QUERY_ENGINE_LIBRARY = "${prisma-engines}/lib/libquery_engine.so.node";
    PRISMA_QUERY_ENGINE_BINARY = "${prisma-engines}/bin/query-engine";
    PRISMA_SCHEMA_ENGINE_BINARY = "${prisma-engines}/bin/schema-engine";
    PRISMA_CLI_QUERY_ENGINE_TYPE = "library";
    PRISMA_CLIENT_ENGINE_TYPE = "library";
  };

  # Frontend: React/Vite SPA, built to static assets served by a web server.
  frontend = buildNpmPackage {
    pname = "${pname}-frontend";
    inherit version src;

    sourceRoot = "${src.name}/frontend";

    npmDeps = fetchNpmDeps {
      name = "${pname}-frontend-npm-deps";
      src = lockDir ./frontend-package-lock.json;
      hash = "sha256-XKLRMfP78dUcRK3jOL5XhyQBfEBbVjzPejdSt58hoX8=";
    };

    npmFlags = ["--legacy-peer-deps"];

    # Replace the stale committed lockfile with our vendored one, and redirect
    # the upstream `bunx --bun <tool>` scripts to the node-based binaries that
    # npm puts on PATH. Skip the `tsc -b` type-check (vite build uses esbuild).
    postPatch = ''
      cp ${./frontend-package-lock.json} package-lock.json
      substituteInPlace package.json \
        --replace-fail "bunx --bun tsc -b && bunx --bun vite build" "vite build"
    '';

    dontNpmInstall = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist/. $out/
      runHook postInstall
    '';
  };

  # Backend: NestJS app bundled with webpack. Ships its node_modules (with the
  # generated Prisma client) since the bundle externalizes dependencies.
  backend = buildNpmPackage {
    pname = "${pname}-backend";
    inherit version src;

    sourceRoot = "${src.name}/backend";

    npmDeps = fetchNpmDeps {
      name = "${pname}-backend-npm-deps";
      src = lockDir ./backend-package-lock.json;
      hash = "sha256-XgK2+MQMVh5xocbxt3ennTHYAqjnekMiZivWgVGLrG0=";
    };

    # --ignore-scripts skips the network-dependent postinstalls of prisma,
    # puppeteer and sharp; we provide Prisma engines and Chromium ourselves.
    npmFlags = ["--legacy-peer-deps" "--ignore-scripts"];

    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [stdenv.cc.cc.lib openssl];

    inherit (prismaEnv) PRISMA_QUERY_ENGINE_LIBRARY PRISMA_QUERY_ENGINE_BINARY PRISMA_SCHEMA_ENGINE_BINARY PRISMA_CLI_QUERY_ENGINE_TYPE PRISMA_CLIENT_ENGINE_TYPE;
    PUPPETEER_SKIP_DOWNLOAD = "true";

    postPatch = ''
      cp ${./backend-package-lock.json} package-lock.json
      substituteInPlace package.json \
        --replace-fail "bun run nest build" "nest build"
    '';

    # Generate the Prisma client before webpack runs so the build can resolve it.
    preBuild = ''
      node ./node_modules/prisma/build/index.js generate
    '';

    dontNpmInstall = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/inker-backend $out/bin
      cp -r dist node_modules prisma assets package.json $out/lib/inker-backend/

      # Static frontend, ready to be served by any web server / reverse proxy.
      mkdir -p $out/share/inker
      cp -r ${frontend} $out/share/inker/frontend

      substitute ${./inker.sh} $out/bin/inker \
        --replace-fail "@shell@" "${stdenv.shell}" \
        --replace-fail "@app@" "$out/lib/inker-backend" \
        --replace-fail "@node@" "${lib.getExe nodejs}" \
        --replace-fail "@chromium@" "${lib.getExe chromium}" \
        --replace-fail "@queryLib@" "${prismaEnv.PRISMA_QUERY_ENGINE_LIBRARY}" \
        --replace-fail "@schemaBin@" "${prismaEnv.PRISMA_SCHEMA_ENGINE_BINARY}" \
        --replace-fail "@queryBin@" "${prismaEnv.PRISMA_QUERY_ENGINE_BINARY}"

      substitute ${./inker-prisma.sh} $out/bin/inker-prisma \
        --replace-fail "@shell@" "${stdenv.shell}" \
        --replace-fail "@app@" "$out/lib/inker-backend" \
        --replace-fail "@node@" "${lib.getExe nodejs}" \
        --replace-fail "@queryLib@" "${prismaEnv.PRISMA_QUERY_ENGINE_LIBRARY}" \
        --replace-fail "@schemaBin@" "${prismaEnv.PRISMA_SCHEMA_ENGINE_BINARY}" \
        --replace-fail "@queryBin@" "${prismaEnv.PRISMA_QUERY_ENGINE_BINARY}"

      chmod +x $out/bin/inker $out/bin/inker-prisma

      runHook postInstall
    '';

    passthru = {
      inherit frontend prisma-engines;
    };

    meta = {
      description = "Self-hosted e-ink device management server (TRMNL/BYOS)";
      homepage = "https://github.com/usetrmnl/inker";
      license = lib.licenses.agpl3Only;
      maintainers = [];
      mainProgram = "inker";
      platforms = ["x86_64-linux"];
    };
  };
in
  backend
