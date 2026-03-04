{
  pkgs,
  lib,
  ...
}:
pkgs.qutebrowser.overrideAttrs (oldAttrs: {
  version = "3.6.3";

  src = pkgs.fetchFromGitHub {
    owner = "giodamelio";
    repo = "qutebrowser";
    rev = "e48c8c5e79479032d8aecd7a7ae3874702436a9a";
    hash = "sha256-NRq6klZPPBDN2LvYLEsdbjkD8PjoSRToaarNATWzBrg=";
  };

  meta =
    oldAttrs.meta
    // {
      description = "qutebrowser from giodamelio's fork";
    };
})
