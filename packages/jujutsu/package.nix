{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "d52755b8dbd43291be6cb106b65e645c5b4448a0";
    hash = "sha256-BTpq8QyUma+FdpiPYU2l7lUkBQlDIt3Re3O9nYMJnoM=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0-unstable-2026-05-16";

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
