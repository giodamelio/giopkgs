{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "7baeebad5e68aa79661de46dace58b1818bb96e0";
    hash = "sha256-kpGm+GzfeGJ5jh5k0Z+r4lgbHOCfaKuo8qCoJAKiFwA=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0-unstable-2026-05-11";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-ZMNd/AC3Nm2h0lLy4VYWlJUG9cD1eOJFhgmzQUWrEmQ=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    passthru.updateScript = ./update.sh;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
