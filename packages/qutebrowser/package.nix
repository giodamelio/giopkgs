{pkgs, ...}:
pkgs.qutebrowser.overrideAttrs (oldAttrs: {
  version = "3.7.0-unstable-2026-09-26";

  src = pkgs.fetchFromGitHub {
    owner = "giodamelio";
    repo = "qutebrowser";
    rev = "1a879651a069b523585bbd8138a78c899e59d0e4";
    hash = "sha256-uDlU0Gfd2wHgaLII6eerLwhP8XPmA3k7S29yPWwQuAg=";
  };

  meta =
    oldAttrs.meta
    // {
      description = "qutebrowser from giodamelio's fork";
    };
})
