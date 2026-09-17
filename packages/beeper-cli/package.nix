{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  gnutar,
  gzip,
  testers,
}: let
  sources = lib.importJSON ./sources.json;
  source =
    sources.assets.${stdenv.hostPlatform.system}
    or (throw "beeper-cli: unsupported platform ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "beeper-cli";
    inherit (sources) version;

    src = fetchurl {inherit (source) url hash;};

    # The tarball has no root directory — it unpacks ./bin/beeper into cwd.
    sourceRoot = ".";

    nativeBuildInputs = [autoPatchelfHook makeWrapper];

    dontConfigure = true;
    dontBuild = true;

    # The CLI is a bun single-file executable. Stripping drops the embedded
    # bundle, leaving a binary that silently behaves as plain `bun` —
    # `--version` then prints bun's version instead of the CLI's.
    dontStrip = true;

    # On its first run the binary unpacks a 390 MB payload (its node_modules)
    # into $BEEPER_CLI_BINARY_CACHE_DIR, or ~/.cache/beeper-cli/binary, by
    # shelling out to `tar -xzf` — hence tar and gzip on PATH. That payload was
    # rolled up on macOS, so GNU tar otherwise prints one AppleDouble xattr
    # warning per file, several hundred lines of them.
    installPhase = ''
      runHook preInstall

      install -Dm755 bin/beeper $out/bin/beeper
      wrapProgram $out/bin/beeper \
        --prefix PATH : ${lib.makeBinPath [gnutar gzip]} \
        --set-default TAR_OPTIONS --warning=no-unknown-keyword

      runHook postInstall
    '';

    # Guards the strip trap above: a stripped binary reports bun's version.
    passthru.tests.version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "HOME=$(mktemp -d) beeper --version";
    };

    meta = {
      description = "One CLI for all your chats, backed by Beeper Desktop or Beeper Server";
      homepage = "https://github.com/beeper/cli";
      license = lib.licenses.mit;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = lib.attrNames sources.assets;
      maintainers = [];
      mainProgram = "beeper";
    };
  })
