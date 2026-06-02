{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "ca26b6b83411690b6f51b0bc1ab114ede79f7b58";
    hash = "sha256-r8DIXyg+4PJJvGS7TgLlQkhqlY+GNxe3QvyIE11lZc0=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0.41.0-unstable-2026-06-02";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-1u1Z5qjSQ7OtOhia/fmtxRuPIjSSIBxUhjIWZuWkE7U=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    passthru.updateScript = ./update.sh;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
