{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "38cb8a289c0fb898b974d051790e4d7e2d783031";
    hash = "sha256-kTubBTQ0pw4RaT/AJkKMfgk+pu3fgnse2AwPcJ67pAo=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0.40.0-unstable-2026-04-27";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-hRD8SBCgPsjHqi98PafB8dkFvPGPAgn8hPx6nnZfUWw=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    passthru.updateScript = ./update.sh;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
