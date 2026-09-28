{pkgs, ...}:
pkgs.qutebrowser.overrideAttrs (oldAttrs: {
  version = "3.7.0-unstable-2026-09-28";

  src = pkgs.fetchFromGitHub {
    owner = "giodamelio";
    repo = "qutebrowser";
    rev = "ceaf12742ea853448d61ea1f25be9b7483b20504";
    hash = "sha256-ILo5eTq51mQE8BV6kMiguto9+J5+9SpOBBdCiQsfrtc=";
  };

  meta =
    oldAttrs.meta
    // {
      description = "qutebrowser from giodamelio's fork";
    };
})
