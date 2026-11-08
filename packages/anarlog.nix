{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
  cacert,
  dpkg,
  glib-networking,
  libgpg-error,
  libopus,
  libx11,
  libxcb,
  mpg123,
  writeText,
  zlib,
}: let
  version = "1.4.34";

  # The host's pipewire ALSA plugin is built against the *system* alsa-lib, and
  # this flake's nixpkgs ships a different one (1.2.16.1 vs 1.2.15.3), so
  # dlopening it inside the FHS env fails and no capture device shows up at all.
  # Route through pipewire-pulse instead: alsa-plugins' `pulse` PCM is built
  # against the same alsa-lib as the env, so it always matches.
  asoundConf = writeText "anarlog-asound.conf" ''
    <//usr/share/alsa/alsa.conf>
    pcm.!default { type pulse }
    ctl.!default { type pulse }
  '';

  x86_64Hash = "sha256-1wz9G90la4HUUOJI4uzD06ckdAoYfBG8vR0iqS0qf+o=";
  aarch64Hash = "sha256-pgNyAc3fzXF++GXJQ+Fig5mKGz2a4JIxVvoIeULe07Y=";

  # The AppImage bundles Ubuntu noble's WebKitGTK and GStreamer 1.24.2 core but
  # no GStreamer plugins, so WebKit's media player cannot build a pipeline and
  # the transcript view freezes. nixpkgs' plugins are no use: the 1.24 core
  # refuses newer plugins, and swapping in nixpkgs' whole stack breaks WebKit's
  # rendering. These are the plugins built for exactly this core. Release-pocket
  # versions, because the Ubuntu pool never drops those.
  gstVersion = "1.24.2";
  gstDebs = {
    x86_64-linux = {
      arch = "amd64";
      mirror = "https://archive.ubuntu.com/ubuntu";
      triple = "x86_64-linux-gnu";
      hashes = {
        core = "sha256-kCUmOUMPdXIKpdfh2WEFMhITCx32g1ou7FQ4f8jhK3U=";
        tools = "sha256-P0fCFD3ODynVWWLWAS7LCtdQ8Tee2AEtY6TdO2oMK8Y=";
        base = "sha256-1p4NJI0HKpiFgf2dsa+e3fMsVwHffYTQS2n9lMmlekY=";
        good = "sha256-oYFXCzJkGLP/oTYjn4a8YphFepARX5BFDQSiEkwr1IU=";
        bad = "sha256-VvR8Kms5ByJBbJYlZNpqtfxzFdy6plP+RFeo227TTKY=";
      };
    };
    aarch64-linux = {
      arch = "arm64";
      mirror = "https://ports.ubuntu.com/ubuntu-ports";
      triple = "aarch64-linux-gnu";
      hashes = {
        core = "sha256-MDble6OF5Gpq/wY45ZY/6gQsrIA+yij0n8QZ1ugH1mM=";
        tools = "sha256-P5rJ1zHJxzNJHlQfRG/JhhspeFqFLxOKDmTt8VTZOeM=";
        base = "sha256-gMYBa+BJ0A3REApwmA+ht0Lokco5kDmrtdYtN7KxsJM=";
        good = "sha256-IcHfNY6WXnDWfW4+VkEmnkITBfvImuEiQRnSyWLqFME=";
        bad = "sha256-SUjOedThc+xQYFGIeECC8hYef9N0pYTijbONROjPRv8=";
      };
    };
  };

  # What WebKit's media player and WebAudio use to play the .mp3 recordings.
  # fakevideosink is in debugutilsbad and the WebVTT encoder in subenc.
  gstPlugins = [
    "app"
    "audioconvert"
    "audioparsers"
    "audiorate"
    "audioresample"
    "autodetect"
    "coreelements"
    "debugutilsbad"
    "id3demux"
    "interleave"
    "mpg123"
    "opus"
    "playback"
    "pulseaudio"
    "subenc"
    "typefindfunctions"
    "volume"
  ];

  images = {
    x86_64-linux = {
      arch = "x86_64";
      hash = x86_64Hash;
    };
    aarch64-linux = {
      arch = "aarch64";
      hash = aarch64Hash;
    };
  };

  image =
    images.${stdenv.hostPlatform.system}
    or (throw "anarlog: unsupported platform ${stdenv.hostPlatform.system}");

  gstDeb = gstDebs.${stdenv.hostPlatform.system};

  fetchGstDeb = key: component: dir: pkg: rev:
    fetchurl {
      url = "${gstDeb.mirror}/pool/${component}/g/${dir}/${pkg}_${gstVersion}-${rev}_${gstDeb.arch}.deb";
      hash = gstDeb.hashes.${key};
    };

  debs = [
    (fetchGstDeb "core" "main" "gstreamer1.0" "libgstreamer1.0-0" "1")
    (fetchGstDeb "tools" "main" "gstreamer1.0" "gstreamer1.0-tools" "1")
    (fetchGstDeb "base" "main" "gst-plugins-base1.0" "gstreamer1.0-plugins-base" "1")
    (fetchGstDeb "good" "main" "gst-plugins-good1.0" "gstreamer1.0-plugins-good" "1ubuntu1")
    (fetchGstDeb "bad" "universe" "gst-plugins-bad1.0" "gstreamer1.0-plugins-bad" "1ubuntu4")
  ];

  src = fetchurl {
    url = "https://github.com/fastrepl/anarlog/releases/download/desktop_v${version}/anarlog-linux-${image.arch}.AppImage";
    inherit (image) hash;
  };

  # AppRun.wrapped points GST_PLUGIN_SYSTEM_PATH_1_0 at usr/lib/gstreamer-1.0,
  # so the plugins go there. The bundled libssl lacks OPENSSL_3.5.0, which host
  # curl needs, so it and libcrypto give way to the env's newer OpenSSL.
  contents = appimageTools.extract {
    inherit src version;
    pname = "anarlog";
    postExtract = ''
      if [ "$(tr '\0' '\n' < $out/usr/lib/libgstreamer-1.0.so.0 | grep -cx '${gstVersion}')" = 0 ]; then
        echo "anarlog: bundled GStreamer is no longer ${gstVersion}; update gstDebs" >&2
        exit 1
      fi

      chmod u+w $out/usr/lib
      rm $out/usr/lib/libssl.so.3 $out/usr/lib/libcrypto.so.3

      debroot=$(mktemp -d)
      for deb in ${lib.concatStringsSep " " debs}; do
        ${dpkg}/bin/dpkg-deb -x $deb $debroot
      done
      plugindir=$debroot/usr/lib/${gstDeb.triple}/gstreamer-1.0
      install -Dm555 -t $out/usr/lib/gstreamer-1.0 \
        ${lib.concatMapStringsSep " " (p: "$plugindir/libgst${p}.so") gstPlugins}
      # debugutilsbad links it, and the env's newer copy needs a newer GLib.
      cp -P $debroot/usr/lib/${gstDeb.triple}/libgstnet-1.0.so* $out/usr/lib/

      # Build the plugin registry now, so GStreamer never scans or writes a
      # cache at runtime. A plugin that fails to load here would be recorded
      # as broken for good, so every one is checked.
      gst_inspect() {
        GST_REGISTRY_1_0=$out/usr/lib/gstreamer-registry.bin \
        GST_PLUGIN_SYSTEM_PATH_1_0=$out/usr/lib/gstreamer-1.0 \
        GST_REGISTRY_FORK=no \
          ${stdenv.cc.bintools.dynamicLinker} \
          --library-path $out/usr/lib:${lib.makeLibraryPath [libgpg-error libopus libx11 libxcb mpg123 zlib]} \
          $debroot/usr/bin/gst-inspect-1.0 "$@"
      }
      for plugin in ${lib.concatStringsSep " " gstPlugins}; do
        if ! gst_inspect $plugin > /dev/null; then
          echo "anarlog: GStreamer plugin $plugin failed to load" >&2
          exit 1
        fi
      done
    '';
  };
in
  # Not wrapType2: it rebuilds `contents` from `src`, discarding postExtract.
  appimageTools.wrapAppImage {
    pname = "anarlog";
    inherit version src contents;

    extraPkgs = pkgs:
      with pkgs; [
        alsa-lib
        alsa-plugins
        cacert
        glib-networking
        libayatana-appindicator
        # Linked by the GStreamer plugins but not shipped in the bundle.
        libgpg-error
        libopus
        libpulseaudio
        libsoup_3
        # Also for the GStreamer plugins.
        mpg123
        openssl
        pipewire
        webkitgtk_4_1
      ];

    profile = ''
      export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
      export GIO_MODULE_DIR="${glib-networking}/lib/gio/modules/"
      export ALSA_CONFIG_PATH="${asoundConf}"
      export GST_REGISTRY_1_0="${contents}/usr/lib/gstreamer-registry.bin"
      export GST_REGISTRY_UPDATE=no
    '';

    extraInstallCommands = ''
      install -Dm444 ${contents}/Anarlog.desktop \
        $out/share/applications/anarlog.desktop
      cp -r ${contents}/usr/share/icons $out/share/icons
    '';

    # The release tag is `desktop_v1.4.34`, and both arch hashes move together.
    passthru.updatePolicy = "skip";

    meta = {
      description = "Open source Granola AI alternative for meeting notes";
      homepage = "https://anarlog.so";
      license = lib.licenses.mit;
      maintainers = [];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = lib.attrNames images;
      mainProgram = "anarlog";
    };
  }
