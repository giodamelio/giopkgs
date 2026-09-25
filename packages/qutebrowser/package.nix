{pkgs, ...}:
pkgs.qutebrowser.overrideAttrs (oldAttrs: {
  version = "3.7.0-unstable-2026-09-25";

  src = pkgs.fetchFromGitHub {
    owner = "giodamelio";
    repo = "qutebrowser";
    rev = "4d5c4a83d5a14886180e7bccdc042e2e61ee509a";
    hash = "sha256-DCjEjNFWKBDH9pKgXxcyKWmULZTCHMk4P3s2qsxTSGM=";
  };

  passthru =
    (oldAttrs.passthru or {})
    // {
      updatePolicy = "branch";
    };

  meta =
    oldAttrs.meta
    // {
      description = "qutebrowser from giodamelio's fork";
    };
})
