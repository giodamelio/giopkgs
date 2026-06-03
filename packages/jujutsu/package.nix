{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "aafd1c865db87c72e32f0148205f17f30e898141";
    hash = "sha256-Q9DSgoxg2xJ78GoubrIFIMS/3H8ZpOjXZ+ZSYDbdnnY=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0.41.0-unstable-2026-06-03";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-40TUyFbxXxwX7yvR6A3Y6zAwX6wSGY+XdKeenQOcRYo=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    passthru.updateScript = ./update.sh;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
