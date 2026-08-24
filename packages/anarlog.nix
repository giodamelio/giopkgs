{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
  cacert,
  glib-networking,
  writeText,
}: let
  version = "1.4.13";

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

  x86_64Hash = "sha256-2CIGQ9q0UDuv2xCPZdV1qTvSZT0n9f8N7JkDkzPucmg=";
  aarch64Hash = "sha256-axJcX1m1BRL8c22IHY2MluMMYdQTQngs9bdC1ab+Svc=";

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

  src = fetchurl {
    url = "https://github.com/fastrepl/anarlog/releases/download/desktop_v${version}/anarlog-linux-${image.arch}.AppImage";
    inherit (image) hash;
  };

  contents = appimageTools.extract {
    inherit src version;
    pname = "anarlog";
  };
in
  appimageTools.wrapType2 {
    pname = "anarlog";
    inherit version src;

    extraPkgs = pkgs:
      with pkgs; [
        alsa-lib
        alsa-plugins
        cacert
        glib-networking
        libayatana-appindicator
        libpulseaudio
        libsoup_3
        openssl
        webkitgtk_4_1
      ];

    profile = ''
      export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
      export GIO_MODULE_DIR="${glib-networking}/lib/gio/modules/"
      export ALSA_CONFIG_PATH="${asoundConf}"
    '';

    extraInstallCommands = ''
      install -Dm444 ${contents}/Anarlog.desktop \
        $out/share/applications/anarlog.desktop
      cp -r ${contents}/usr/share/icons $out/share/icons
    '';

    # The release tag is `desktop_v1.4.13`, and both arch hashes move together.
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
