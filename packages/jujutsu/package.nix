{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "51b103b243d66e3bdbd34e236f8e913f53b85cfa";
    hash = "sha256-sjyLRHfQmZcVwuhAzPC/cItt0iiMRokkT9gb2Hnz4s4=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0-unstable-2026-05-13";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-ZshQPiQae5SWtfcCP42KrA/38q0Vc4H7lZBJJmn8uPE=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    passthru.updateScript = ./update.sh;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
