{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  fetchPnpmDeps,
  nodejs_22,
  pnpm_10,
  pnpmConfigHook,
  autoPatchelfHook,
  makeWrapper,
  python3,
  pkg-config,
  openssl,
  libtool,
  autoconf,
  automake,
  libsecret,
  sqlite,
  zlib,
  libutempter,
  patchelf,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  gsettings-desktop-schemas,
  libglvnd,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  runCommand,
}: let
  nodejs = nodejs_22;
  pnpm = pnpm_10.override {inherit nodejs;};

  electronVersion = "40.7.0";
  electronArch =
    {
      x86_64-linux = "x64";
      aarch64-linux = "arm64";
    }
    .${
      stdenv.hostPlatform.system
    };

  electronLinuxZip = fetchurl {
    url = "https://github.com/electron/electron/releases/download/v${electronVersion}/electron-v${electronVersion}-linux-${electronArch}.zip";
    sha256 =
      {
        x86_64-linux = "sha256-D3utkbADhMTStZ6++QRBW+lb8G7b/llfD8tX9R/RR+Q=";
        aarch64-linux = "sha256-/dUAOLRDa5d1hdo94KTxGK79h/Ex7jQqZR1h6R6qFQs=";
      }
      .${
        stdenv.hostPlatform.system
      };
  };

  electronDistDir = runCommand "electron-dist" {} ''
    mkdir -p $out
    cp ${electronLinuxZip} $out/electron-v${electronVersion}-linux-${electronArch}.zip
  '';

  electronHeaders = fetchurl {
    url = "https://www.electronjs.org/headers/v${electronVersion}/node-v${electronVersion}-headers.tar.gz";
    sha256 = "sha256-M+UG5J/dCUxVE0lzNeMl4IP7nJs1WwvAtSyFfApbUR4=";
  };

  electronHeadersDir = runCommand "electron-headers" {} ''
    mkdir -p $out
    tar xzf ${electronHeaders} -C $out --strip-components=1
  '';
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "emdash";
    version = "1.1.6-unstable-2025-04-29";

    src = fetchFromGitHub {
      owner = "giodamelio";
      repo = "emdash";
      rev = "7e2b2cee515b56512b45b2f7fbed085bef3c3d35";
      hash = "sha256-WkrDOL/+MfRBmzwIAk9osu3aNyR6vNGUHlmXO+npifI=";
    };

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      inherit pnpm;
      fetcherVersion = 1;
      hash = "sha256-CqS39LSztynmS12Gifdo1OmlttiYnBfXphwlscrED9Y=";
    };

    nativeBuildInputs = [
      nodejs
      pnpm
      pnpmConfigHook
      autoPatchelfHook
      makeWrapper
      python3
      pkg-config
      openssl
      libtool
      autoconf
      automake
      patchelf
    ];

    buildInputs = [
      libsecret
      sqlite
      zlib
      libutempter
      alsa-lib
      at-spi2-atk
      cairo
      cups
      dbus
      expat
      gdk-pixbuf
      glib
      gtk3
      libdrm
      libGL
      libxkbcommon
      mesa
      nspr
      nss
      pango
      gsettings-desktop-schemas
      libglvnd
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
    ];

    env = {
      HOME = "$TMPDIR/emdash-home";
      npm_config_build_from_source = "true";
      npm_config_manage_package_manager_versions = "false";
      ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
      EMDASH_SKIP_ELECTRON_REBUILD = "1";
      npm_config_nodedir = "${electronHeadersDir}";
    };

    buildPhase = ''
      runHook preBuild

      mkdir -p "$TMPDIR/emdash-home"

      # cpu-features is an optional dep that requires a git submodule not present in the tarball
      rm -rf node_modules/cpu-features

      pnpm exec electron-rebuild -f --only=better-sqlite3,node-pty
      pnpm run build

      pnpm exec electron-builder --linux --dir \
        --config electron-builder.config.ts \
        -c.electronDist=${electronDistDir}

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      install -d $out/share/emdash
      cp -R release/linux-unpacked $out/share/emdash/

      install -d $out/bin
      makeWrapper "$out/share/emdash/linux-unpacked/emdash" "$out/bin/emdash" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        libglvnd
        mesa
        libGL
      ]}" \
        --prefix GSETTINGS_SCHEMA_DIR : "${gsettings-desktop-schemas}/share/glib-2.0/schemas"

      runHook postInstall
    '';

    passthru.updateScript = ./update.sh;

    meta = {
      description = "Multi-agent orchestration desktop app";
      homepage = "https://emdash.sh";
      license = lib.licenses.asl20;
      maintainers = [];
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "emdash";
    };
  })
