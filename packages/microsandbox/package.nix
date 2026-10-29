{
  lib,
  callPackage,
  rustPlatform,
  pkgsStatic,
  fetchFromGitHub,
  pkg-config,
  bzip2,
  sqlite,
  zstd,
  versionCheckHook,
}: let
  version = "0.7.11";

  src = fetchFromGitHub {
    owner = "superradcompany";
    repo = "microsandbox";
    tag = "v${version}";
    hash = "sha256-FDj5o0TiTt50ESnBV58klaHbQ1TocFbUFg/thxxRO5g=";
  };

  cargoHash = "sha256-OPyrM15mpeV5/ZngwV2ml9rINYt6kA6ILZ2aZD7HYI4=";

  libkrunfw = callPackage ./libkrunfw.nix {};

  # The guest init runs inside the microVM's own rootfs, so it must be a
  # static musl executable. msb embeds it at compile time.
  agentd = pkgsStatic.rustPlatform.buildRustPackage {
    pname = "microsandbox-agentd";
    inherit version src cargoHash;
    cargoBuildFlags = ["--package" "microsandbox-agentd"];
    doCheck = false;
  };

  goFfi = callPackage ./go-ffi.nix {inherit version src cargoHash;};
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "microsandbox";
    inherit version src cargoHash;

    cargoBuildFlags = ["--package" "microsandbox-cli"];

    # The default features include download-binaries, whose build scripts
    # fetch a release bundle and agentd from GitHub into ~/.microsandbox.
    # embed-binaries alone reads agentd from MSB_EMBED_ARTIFACTS_DIR instead.
    buildNoDefaultFeatures = true;
    buildFeatures = ["embed-binaries" "net" "keyring" "ssh"];
    env = {
      MSB_EMBED_ARTIFACTS_DIR = "${agentd}/bin";
      LIBSQLITE3_SYS_USE_PKG_CONFIG = "1";
      ZSTD_SYS_USE_PKG_CONFIG = "1";
    };

    # Upstream's rpaths point at a dev checkout's build/ directory. msb never
    # links libkrunfw: it hands the path to libkrun, found beside the binary.
    postPatch = ''
      rm .cargo/config.toml
      grep -qx 'pub const LIBKRUNFW_VERSION: &str = "${libkrunfw.version}";' crates/utils/lib/lib.rs \
        || { echo "LIBKRUNFW_VERSION in crates/utils/lib/lib.rs does not match libkrunfw ${libkrunfw.version}" >&2; exit 1; }
    '';

    nativeBuildInputs = [pkg-config];
    buildInputs = [bzip2 sqlite zstd];

    # The test suite boots microVMs and needs /dev/kvm.
    doCheck = false;

    nativeInstallCheckInputs = [versionCheckHook];
    doInstallCheck = true;

    # The runtime resolves libkrunfw as <msb>/../lib/libkrunfw.so.<version>
    # after canonicalising msb, so this layout needs no environment at all.
    postInstall = ''
      mkdir -p $out/lib
      ln -s ${libkrunfw}/lib/libkrunfw.so* $out/lib/
    '';

    passthru = {
      inherit agentd libkrunfw;
      inherit goFfi;

      # For a service that drives an SDK. MICROSANDBOX_FFI_PATH is read only
      # by Go programs built with `-tags microsandbox_ffi_path`.
      runtimeEnv = {
        MSB_PATH = "${finalAttrs.finalPackage}/bin/msb";
        MSB_LIBKRUNFW_PATH = "${libkrunfw}/lib/libkrunfw.so.${libkrunfw.version}";
        MICROSANDBOX_FFI_PATH = "${goFfi}/lib/libmicrosandbox_go_ffi.so";
      };

      tests.go-ffi = callPackage ./go-ffi-test.nix {microsandbox = finalAttrs.finalPackage;};
    };

    meta = {
      description = "Self-hosted microVM sandboxes for untrusted code, built on libkrun";
      homepage = "https://github.com/superradcompany/microsandbox";
      license = lib.licenses.asl20;
      maintainers = [];
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "msb";
    };
  })
