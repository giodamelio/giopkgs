{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "c0b60f0e491b1f660421f93bc00afdaaf0c6e097";
    hash = "sha256-62q0SlbSOxN415u9Q6e8yokcwPSdeqGF6wMVms98k94=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0.40.0-unstable-2026-04-24";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-jX23IiMlsPmVzCQPKzAEOCiOdXwsXUV3VEufLxUsNSg=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    passthru.updateScript = ./update.sh;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
