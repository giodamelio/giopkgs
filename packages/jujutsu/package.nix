{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "0aa2f870b466c812058560d4d1ef8a37b3472486";
    hash = "sha256-BhoeOtBSr303nD1IgIS2Df2Se4jDGq3ocT+kgU3qC+k=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0.40.0-unstable-2026-04-30";

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
