{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "giodamelio";
    repo = "wezterm";
    rev = "b120f6b7c519a4b1de49ef19ff19b9bc589130e1"; # branch: all-patches
    fetchSubmodules = true;
    hash = "sha256-XTX+l5vHgWddNvEI7MiBc0IdgQ1RTWBfKeBAOf9+4K4=";
  };
in
  pkgs.wezterm.overrideAttrs (oldAttrs: {
    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "wezterm-all-patches-vendor";
      hash = "sha256-iGmRjTHK5JDC3em2DqtxAhN8Hmd9Krj2ISkzTNzGDmQ=";
    };

    passthru =
      (oldAttrs.passthru or {})
      // {
        updateScript = ./../scripts/skip-update.sh;
      };

    meta =
      oldAttrs.meta
      // {
        description = "Wezterm from giodamelio/wezterm all-patches branch";
      };
  })
