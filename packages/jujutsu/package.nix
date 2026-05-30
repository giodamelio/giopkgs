{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "2cc8c83ac2b27db832d132e47cfc0a45b1cd5c9f";
    hash = "sha256-TWbDeHBOBjB+CRv5oGXlEh9sZprOJ6/tFlj63MdpcTQ=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0-unstable-2026-05-30";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-HRmn+sRcC5MJcxscapWR/8maVD2EwnGatEcXXS68lLs=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    passthru.updateScript = ./update.sh;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
