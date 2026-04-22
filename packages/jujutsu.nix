{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "670f746f2894c1fd06634b6124a32c39046003b4";
    hash = "sha256-DICYloF6Jd5COXjL/W32zsQrDUPCtPDIUdGMZ7sdqF4=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0.40.0-unstable-2026-04-21";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-2QNIY3caxBN2K34NQvsNUrtCaz4rwqD1mU9MasLCGR4=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
