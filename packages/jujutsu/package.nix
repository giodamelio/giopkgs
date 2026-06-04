{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "a8ef9b52859458e912c7b08abad6e3f37dc8687a";
    hash = "sha256-aF+HYkvXnyEIqPlFnJm/m3mPXN2YVupcse3BujuowEs=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0.41.0-unstable-2026-06-04";

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
