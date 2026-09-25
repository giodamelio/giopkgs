{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  pkg-config,
  protobuf,
  bzip2,
  oniguruma,
  sqlite,
  xz,
  zlib,
  zstd,
  versionCheckHook,
  buildNpmPackage,
  installShellFiles,
  # Enterprise Edition ships only as a prebuilt binary
  enableEnterprise ? false,
}: let
  version = "0.92.2";

  commonMeta = {
    description = "Cloud-native observability platform built specifically for logs, metrics, traces, analytics & realtime user-monitoring";
    mainProgram = "openobserve";
    maintainers = [];
  };
in
  if enableEnterprise
  then
    stdenv.mkDerivation (finalAttrs: {
      pname = "openobserve-ee";
      inherit version;
      strictDeps = true;
      __structuredAttrs = true;

      src = fetchurl {
        url = "https://downloads.openobserve.ai/releases/o2-enterprise/v${finalAttrs.version}/openobserve-ee-v${finalAttrs.version}-linux-amd64-musl.tar.gz";
        hash = "sha256-dxV3c10jpkhKOvfHOTO39GLY+oqcx5++7V8OiMXm8wo=";
      };

      # The tarball is a single flat `openobserve` binary.
      sourceRoot = ".";

      dontConfigure = true;
      dontBuild = true;

      nativeBuildInputs = [installShellFiles];

      installPhase = ''
        runHook preInstall
        installBin openobserve
        runHook postInstall
      '';

      doInstallCheck = true;
      nativeInstallCheckInputs = [versionCheckHook];

      meta =
        commonMeta
        // {
          homepage = "https://openobserve.ai/";
          sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
          license = {
            fullName = "OpenObserve Enterprise Edition License Agreement";
            url = "https://openobserve.ai/legal/enterprise-license/";
            free = false;
            redistributable = false;
          };
          platforms = lib.intersectLists lib.platforms.x86_64 lib.platforms.linux;
        };
    })
  else
    rustPlatform.buildRustPackage (finalAttrs: let
      # The AI data-source cards live in a separate repo that the vite build
      # git-clones from `main`. Pin it here and stage it as the script's cache
      # instead, so the build neither needs the network nor tracks a branch.
      datasourceContent = fetchFromGitHub {
        owner = "openobserve";
        repo = "o2-datasource";
        rev = "7ea74ba2b8eabe5758c81b928a835144dc1f7f60";
        hash = "sha256-vORes6FEbhijRLTWjEaB+KHOUls2CGBED6WzLF3stnM=";
      };

      web = buildNpmPackage {
        inherit (finalAttrs) src version;
        pname = "openobserve-ui";

        sourceRoot = "${finalAttrs.src.name}/web";

        npmDepsHash = "sha256-obgbExrZhoREkMLkSdBCTGMl8rLcB9tPBQ0BBn/TrtM=";

        # `generated/` is what scripts/fetch-datasource-content.mjs would have
        # written; `.fetch.json` is the marker it checks to skip the clone.
        postPatch = ''
          generated=src/assets/ai-datasource-content/generated
          mkdir -p "$generated"
          cp -r ${datasourceContent}/datasource-ui-content/. "$generated"/
          chmod -R u+w "$generated"
          cat > "$generated/.fetch.json" <<EOF
          {
            "repo": "https://github.com/openobserve/o2-datasource.git",
            "ref": "${datasourceContent.rev}",
            "sha": "${datasourceContent.rev}"
          }
          EOF
        '';

        env = {
          NODE_OPTIONS = "--max-old-space-size=8192";
          # cypress tries to download binaries otherwise
          CYPRESS_INSTALL_BINARY = 0;
          # Otherwise vite forces a refetch on every build and ignores the cache
          # staged above.
          DS_CONTENT_FORCE = "0";
        };

        installPhase = ''
          runHook preInstall
          mkdir -p $out/share
          mv dist $out/share/openobserve-ui
          runHook postInstall
        '';
      };
    in {
      pname = "openobserve";
      inherit version;

      src = fetchFromGitHub {
        owner = "openobserve";
        repo = "openobserve";
        tag = "v${version}";
        hash = "sha256-iuRrFbfSCcOI9mdzvCb3hyI5J+yqryEAHS3ulaTIzkQ=";
      };

      patches = [
        # prevent using git to determine version info during build time
        ./build.rs.patch
      ];

      # vortex's lib.rs include_str!s its README, which lives at the git
      # workspace root and so is left out of the vendored crate.
      preBuild = ''
        for crate in "$NIX_BUILD_TOP"/${finalAttrs.cargoDeps.name}/source-git-*/vortex-0.1.0; do
          touch "$crate/README.md"
        done
        cp -r ${web}/share/openobserve-ui web/dist
      '';

      cargoHash = "sha256-kPMJy5E2WebJHrbAZerHfDkAZs2ahEQZRWZIJ3ZXBMI=";

      nativeBuildInputs = [
        pkg-config
        protobuf
        rustPlatform.bindgenHook
      ];

      buildInputs = [
        bzip2
        oniguruma
        sqlite
        xz
        zlib
        zstd
      ];

      env = {
        RUSTONIG_SYSTEM_LIBONIG = true;
        ZSTD_SYS_USE_PKG_CONFIG = true;

        RUSTC_BOOTSTRAP = 1; # uses experimental features

        # the patched build.rs file sets these variables
        GIT_VERSION = finalAttrs.src.tag;
        GIT_COMMIT_HASH = "builtByNix";
        GIT_BUILD_DATE = "1970-01-01T00:00:00Z";

        RUSTFLAGS = "-C target-feature=+aes,+sse2";
      };

      # utoipa-swagger-ui unpacks its vendored archive into the target directory
      # again during the check phase; leaving the build-phase copy in place makes
      # that fail with `PermissionDenied`.
      preCheck = ''
        rm -rf target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/build/
      '';

      # Upstream release builds run `cargo build` only, and the doctest examples
      # fail outside an async context.
      cargoTestFlags = [
        "--lib"
        "--bins"
        "--tests"
        "--examples"
      ];

      # requires network access or filesystem mutations
      checkFlags = [
        "--skip=cli::basic::http::tests::test_node_operations_network_failure"
        "--skip=cli::basic::http::tests::test_query_valid_time_range"
        "--skip=common::meta::telemetry::test_telemetry::test_telemetry_send_track_event_without_base_info_or_zo_data"
        "--skip=handler::http::router::tests::test_get_proxy_routes"
        "--skip=tests::e2e_test"
        "--skip=tests::test_setup_logs"
        "--skip=handler::http::router::middlewares::compress::Compress"
        "--skip=service::alerts::destinations::tests::test_alert_destination_requires_template"
        "--skip=service::enrichment_table::url_processor"
        "--skip=service::github"
        "--skip=service::sourcemaps"
        # The tests share database state and are not threadsafe.
        # https://github.com/openobserve/openobserve/pull/7084
        "--test-threads=1"
      ];

      doInstallCheck = true;
      nativeInstallCheckInputs = [versionCheckHook];

      meta =
        commonMeta
        // {
          homepage = "https://github.com/openobserve/openobserve";
          changelog = "https://github.com/openobserve/openobserve/releases/tag/v${version}";
          # Relicensed from Apache 2.0; nixpkgs still carries the old value.
          license = lib.licenses.agpl3Only;
          platforms = lib.platforms.linux ++ lib.platforms.darwin;
        };
    })
