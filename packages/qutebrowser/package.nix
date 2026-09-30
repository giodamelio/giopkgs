{pkgs, ...}:
pkgs.qutebrowser.overrideAttrs (oldAttrs: {
  version = "3.7.0-unstable-2026-09-28";

  src = pkgs.fetchFromGitHub {
    owner = "giodamelio";
    repo = "qutebrowser";
    rev = "e94da1f92f2842ff9094c54fdb84266665c170cc";
    hash = "sha256-mYAmu29+PT9oOic7khXIFDHVKii0dfQJD66BADkiNdQ=";
  };

  meta =
    oldAttrs.meta
    // {
      description = "qutebrowser from giodamelio's fork";
    };
})
