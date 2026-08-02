{
  lib,
  stdenv,
  callPackage,
  fetchzip,
  autoPatchelfHook,
  openssl,
}: let
  sources = lib.importJSON ./sources.json;
  source =
    sources.assets.${stdenv.hostPlatform.system}
    or (throw "tlbx: unsupported platform ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "tlbx";
    inherit (sources) version;

    src = fetchzip {
      inherit (source) url hash;
      stripRoot = false;
    };

    nativeBuildInputs = [autoPatchelfHook];

    # .NET's crypto layer dlopens libssl by soname rather than linking it, so it
    # is invisible to autoPatchelf and mt aborts with "No usable version of
    # libssl was found" without this.
    runtimeDependencies = [openssl.out];

    dontConfigure = true;
    dontBuild = true;

    # version.json is the release manifest `mt --apply-update` reads out of the
    # install directory, so it goes beside the binaries the way upstream's
    # installer lays it out. Self-update itself cannot work from a read-only
    # store path — rebuild the package instead.
    installPhase = ''
      runHook preInstall

      install -Dm755 -t $out/bin mt mthost mtagenthost
      install -Dm644 -t $out/bin version.json

      runHook postInstall
    '';

    passthru.tests = {
      startup = callPackage ./startup-test.nix {tlbx = finalAttrs.finalPackage;};
    };

    meta = {
      description = "Self-hosted browser control station for AI coding agents running on your own machines";
      homepage = "https://github.com/tlbx-ai/tlbx";
      license = lib.licenses.agpl3Only;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      maintainers = [];
      mainProgram = "mt";
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  })
