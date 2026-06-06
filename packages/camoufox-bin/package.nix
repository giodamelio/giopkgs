{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  patchelfUnstable,
  wrapGAppsHook3,
  adwaita-icon-theme,
  alsa-lib,
  curl,
  dbus-glib,
  gtk3,
  libva,
  libxtst,
  pciutils,
  pipewire,
}: let
  sources = lib.importJSON ./sources.json;
  source =
    sources.assets.${stdenv.hostPlatform.system}
    or (throw "camoufox-bin: unsupported platform ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "camoufox-bin";
    inherit (sources) version;

    src = fetchzip {
      inherit (source) url hash;
      stripRoot = false;
    };

    nativeBuildInputs = [
      autoPatchelfHook
      patchelfUnstable
      wrapGAppsHook3
    ];

    buildInputs = [
      adwaita-icon-theme
      alsa-lib
      dbus-glib
      gtk3
      libxtst
    ];

    # Pulled in via the launcher at runtime (dlopen / fork+exec) rather than
    # as direct NEEDED entries, so autoPatchelf can't discover them.
    runtimeDependencies = [
      curl
      libva.out
      pciutils
    ];

    appendRunpaths = ["${pipewire}/lib"];

    # Camoufox (like Firefox) uses "relrhack" to process relocations from a
    # fixed offset; the stable patchelf clobbers those sections and the browser
    # segfaults on startup. patchelfUnstable + this flag preserves them.
    patchelfFlags = ["--no-clobber-old-sections"];

    dontConfigure = true;
    dontBuild = true;

    passthru.updateScript = ./update.sh;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/camoufox
      cp -r . $out/share/camoufox

      mkdir -p $out/bin
      ln -s $out/share/camoufox/camoufox $out/bin/camoufox

      runHook postInstall
    '';

    meta = {
      description = "Anti-detect browser built on Firefox, optimized for web scraping and automation";
      homepage = "https://github.com/daijro/camoufox";
      license = lib.licenses.mpl20;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      maintainers = [];
      mainProgram = "camoufox";
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  }
