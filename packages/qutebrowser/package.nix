{pkgs, ...}:
pkgs.qutebrowser.overrideAttrs (oldAttrs: {
  version = "3.7.0-unstable-2026-09-28";

  src = pkgs.fetchFromGitHub {
    owner = "giodamelio";
    repo = "qutebrowser";
    rev = "ce10ac2540d15b7022a8979997a93c7db4d2f9aa";
    hash = "sha256-TiiLuLh+s1NyKwJxHG4bc6XRUjxu1PRRgsYIX9LEX6g=";
  };

  meta =
    oldAttrs.meta
    // {
      description = "qutebrowser from giodamelio's fork";
    };
})
