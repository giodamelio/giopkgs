{pkgs, ...}:
pkgs.qutebrowser.overrideAttrs (oldAttrs: {
  version = "3.7.0-unstable-2026-09-27";

  src = pkgs.fetchFromGitHub {
    owner = "giodamelio";
    repo = "qutebrowser";
    rev = "fd540ee985e3083c914e2a95c9d886e33cf7c223";
    hash = "sha256-usGwf8Gms6t9lCQkdr5xaw5QwyJG1Pwk7fzafZFhctc=";
  };

  meta =
    oldAttrs.meta
    // {
      description = "qutebrowser from giodamelio's fork";
    };
})
