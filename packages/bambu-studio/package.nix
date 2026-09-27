{pkgs, ...}:
pkgs.appimageTools.wrapType2 rec {
  name = "BambuStudio";
  pname = "bambu-studio";
  version = "02.08.02.61";
  ubuntu_version = "24.04";
  build_timestamp = "20260820225108";

  src = pkgs.fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubuntu${ubuntu_version}-v${version}-${build_timestamp}.AppImage";
    sha256 = "sha256-1QGxA/rFQkUT7A6Na8FF+zBxneLH2U1zINcjdAyBp/0=";
  };

  profile = ''
    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export GIO_MODULE_DIR="${pkgs.glib-networking}/lib/gio/modules/"
  '';

  extraPkgs = pkgs:
    with pkgs; [
      cacert
      glib
      glib-networking
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      webkitgtk_4_1
    ];
}
