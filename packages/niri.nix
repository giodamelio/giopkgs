{
  pkgs,
  fetchFromGitHub,
  ...
}: let
  version = "26.04";

  src = fetchFromGitHub {
    owner = "niri-wm";
    repo = "niri";
    tag = "v${version}";
    hash = "sha256-ehSMsSpE+0k8r+2Vseu8kangsYxToZv3vinynsDp9zs=";
  };
in
  pkgs.niri.overrideAttrs {
    inherit version src;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-gfnalA3qI3a9h3PvsxgQLCrzapfjLLkxhTMJpwRh+ro=";
    };

    # v26.04 changed ExecStart from /usr/bin/niri to just niri,
    # so the nixpkgs postPatch substituteInPlace no longer matches.
    postPatch = ''
      patchShebangs resources/niri-session
    '';

    passthru.updatePolicy = "skip";
  }
