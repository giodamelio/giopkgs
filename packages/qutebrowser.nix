{
  pkgs,
  lib,
  ...
}:
pkgs.qutebrowser.overrideAttrs (oldAttrs: {
  src = pkgs.fetchFromGitHub {
    owner = "giodamelio";
    repo = "qutebrowser";
    rev = "e82b9f07c6c35108eb1ab9e3c8fc631a8e547a52";
    hash = "sha256-WT6NYEOdHBRbXxn6/9LNS/9sSwIUu7Dl+OYwbeLwyXg=";
  };

  meta =
    oldAttrs.meta
    // {
      description = "qutebrowser from giodamelio's fork";
    };
})
