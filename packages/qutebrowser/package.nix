{pkgs, ...}:
pkgs.qutebrowser.overrideAttrs (oldAttrs: {
  version = "3.7.0-unstable-2026-09-26";

  src = pkgs.fetchFromGitHub {
    owner = "giodamelio";
    repo = "qutebrowser";
    rev = "e8658c415915a247d2ec31d8c48c4a99a3e27512";
    hash = "sha256-OTNMy0NOwwU3WnZTkZvdJsRS94EsWaRDTCEEiSUOtCM=";
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
