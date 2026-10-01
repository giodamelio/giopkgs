{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  makeWrapper,
  alsa-lib,
  glib-networking,
  glib,
  gst_all_1,
  gtk3,
  libayatana-appindicator,
  libGL,
  libpulseaudio,
  libsoup_3,
  libva,
  libxkbcommon,
  openssl,
  pipewire,
  procps,
  pulseaudio,
  vulkan-loader,
  wayland,
  webkitgtk_4_1,
  libx11,
  xdg-utils,
}: let
  # pactl finds the monitor source for system audio, which the CLI records too.
  # xdg-open reveals recordings, gsettings reads dark mode and ps checks on the
  # GPUI app; all are run by name.
  runtimePath = lib.makeBinPath [
    glib
    procps
    pulseaudio
    xdg-utils
  ];
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "cap-desktop";
    version = "0.6.0";

    # Upstream publishes Linux builds on the crabnebula CDN under opaque asset ids,
    # not as GitHub release assets; update.nu reads the id from the release notes.
    src = fetchurl {
      url = "https://cdn.crabnebula.app/asset/01M2JEFM7ZZKVZT9YPEKWWFPD7";
      name = "cap-${finalAttrs.version}.deb";
      hash = "sha256-2KJw6++7MDG68AK9kitwqIxRmFq1RTJGcvN0uemQBaQ=";
    };

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
      wrapGAppsHook3
      makeWrapper
    ];

    buildInputs = [
      alsa-lib
      glib-networking
      gtk3
      libsoup_3
      libva
      libxkbcommon
      openssl
      pipewire
      stdenv.cc.cc.lib
      webkitgtk_4_1
      libx11
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-libav
    ];

    # Loaded with dlopen, so autoPatchelfHook cannot see them in DT_NEEDED.
    runtimeDependencies = [
      libayatana-appindicator
      libGL
      libpulseaudio
      vulkan-loader
      wayland
    ];

    dontWrapGApps = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r usr/* $out/

      # Without the marker the in-app updater reports itself unavailable instead
      # of overwriting a store path with a downloaded .deb.
      rm $out/lib/cap/package-format

      # Upstream's CLI installer exposes cap-cli as `cap` through a shim.
      ln -s cap-cli $out/bin/cap

      # Deep links arrive as an argument, so the handler needs %u.
      substituteInPlace $out/share/applications/Cap.desktop \
        --replace-fail "Exec=Cap" "Exec=$out/bin/Cap %u" \
        --replace-fail "Categories=" "Categories=AudioVideo;Video;Recorder;"

      runHook postInstall
    '';

    # Only the GUI binaries need the GTK environment.
    postFixup = ''
      wrapGApp $out/bin/Cap --prefix PATH : ${runtimePath}
      wrapGApp $out/bin/cap-gpui --prefix PATH : ${runtimePath}
      wrapProgram $out/bin/cap-cli --prefix PATH : ${runtimePath}
    '';

    meta = {
      description = "Open source Loom alternative for screen recording";
      homepage = "https://cap.so";
      license = lib.licenses.agpl3Only;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      maintainers = [];
      platforms = ["x86_64-linux"];
      mainProgram = "Cap";
    };
  })
