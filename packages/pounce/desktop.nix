{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  wrapGAppsHook3,
  zstd,
  cairo,
  gdk-pixbuf,
  glib,
  gtk3,
  libayatana-appindicator,
  libsoup_3,
  webkitgtk_4_1,
  version,
}: let
  # Aliases rather than literals inside each record: update.nu edits these by
  # binding name, and two bindings both spelled `hash` in one attrset cannot be
  # told apart structurally.
  amd64Hash = "sha256-57dnRrfXFEOOtDjnXRodAP1EDzGl4lCogdnmIRf3Sq4=";
  arm64Hash = "sha256-gBoxaeWHeR13n7cdan/999EkNRvQalFMveSZFX9MWY0=";

  debs = {
    x86_64-linux = {
      arch = "amd64";
      hash = amd64Hash;
    };
    aarch64-linux = {
      arch = "arm64";
      hash = arm64Hash;
    };
  };

  deb =
    debs.${stdenv.hostPlatform.system}
    or (throw "pounce-desktop: unsupported platform ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "pounce-desktop";
    inherit version;

    src = fetchurl {
      url = "https://github.com/pounce-ai/pounce/releases/download/v${version}/pounce_${version}_${deb.arch}.deb";
      inherit (deb) hash;
    };

    nativeBuildInputs = [
      autoPatchelfHook
      dpkg
      makeWrapper
      wrapGAppsHook3
      zstd
    ];

    buildInputs = [
      cairo
      gdk-pixbuf
      glib
      gtk3
      libayatana-appindicator
      libsoup_3
      webkitgtk_4_1
    ];

    # The .deb's /opt/pounce/bin/launcher is Electrobun's self-extractor: on
    # first run it unpacks Resources/*.tar.zst into XDG_DATA_HOME and hands off
    # to the real launcher inside. Unpacking it here instead skips that
    # write-to-a-writable-dir dance entirely and gives autoPatchelf something to
    # work on.
    unpackPhase = ''
      runHook preUnpack

      dpkg-deb -x $src deb
      tar --use-compress-program=unzstd -xf deb/opt/pounce/Resources/*.tar.zst

      runHook postUnpack
    '';

    dontConfigure = true;
    dontBuild = true;

    dontWrapGApps = true;

    # The .deb calls its binary `pounce`, which is also the CLI's — they collide
    # in the symlinkJoin. This one is the desktop app, so it says so.
    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/pounce $out/share/applications
      cp -r Pounce/. $out/share/pounce/

      # A wrapper, not a symlink: the launcher resolves Resources/main.js and
      # bin/bun relative to /proc/self/exe, which has to stay the real launcher.
      makeWrapper $out/share/pounce/bin/launcher $out/bin/pounce-desktop \
        "''${gappsWrapperArgs[@]}"

      substitute deb/usr/share/applications/pounce.desktop \
        $out/share/applications/pounce.desktop \
        --replace-fail /opt/pounce/bin/launcher $out/bin/pounce-desktop

      install -Dm644 deb/usr/share/icons/hicolor/512x512/apps/pounce.png \
        $out/share/icons/hicolor/512x512/apps/pounce.png

      runHook postInstall
    '';

    # packages/pounce/update.nu drives version and every hash here; nix-update
    # pointed at pounce-desktop would only find a version it must not move alone.
    passthru.updatePolicy = "skip";

    meta = {
      description = "Pounce desktop app: runs the bridge in the tray and serves the full Pounce UI";
      homepage = "https://use-pounce.com";
      license = lib.licenses.mit;
      maintainers = [];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = lib.attrNames debs;
      mainProgram = "pounce-desktop";
    };
  }
