{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "402ffd890c86baaac85d33b0ea2259eb9dded1e0";
    hash = "sha256-DCo70A/RNIdj6pEUbX5IPX4y+xQpGhgfWoTaVpa0EXA=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0.40.0-unstable-2026-05-03";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-TJLSLpSM0nu3lOcYv9+zpRgLaOp9wOH3KxjkMns51z4=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    passthru.updateScript = ./update.sh;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
