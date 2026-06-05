{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "b8f7c455170e3273897aaf94431f8ccfb1afa7ad";
    hash = "sha256-wAefhpNP4ErCTTjZADpvTDk2of/XKP/MoXl6fpG7/fA=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0.42.0-unstable-2026-06-04";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-b7/5vkO6GNX8qzJr4NcxtLZVLDc6NOMrOU4dE6LOFoE=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    passthru.updateScript = ./update.sh;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
