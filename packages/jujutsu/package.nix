{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "b7ac87b2e72efffca1112f208d6e5ae757b58bd3";
    hash = "sha256-kWLGOtchqo1c3AV40SjWEVBwPenffSsWkFXasiV9+bQ=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0-unstable-2026-05-15";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-+ObTR/+XDtZTi9OyYYp7HrN+h4BIpnq8fBYPvHrLPmw=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    passthru.updateScript = ./update.sh;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
