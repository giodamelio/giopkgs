{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "a61bf6efb022ce50e4aa334efd9345ee0d5b24ca";
    hash = "sha256-ouxFYSqL7m8RH9+WTV8rWDHHUlYtziaIeFLcBsGZxcs=";
  };
in
  # REMIND-ME-TO: Remove this override pr_released=github:jj-vcs/jj#9279
  pkgs.jujutsu.overrideAttrs {
    version = "0-unstable-2026-05-09";

    inherit src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-zWfdIac+SsNdfXAfD4NVTl7YfXzAlrK82KNduFgG1EA=";
    };

    # Version check fails because the binary reports a different version than our override
    doInstallCheck = false;

    passthru.updateScript = ./update.sh;

    meta.description = "Git-compatible DVCS (latest main branch)";
  }
