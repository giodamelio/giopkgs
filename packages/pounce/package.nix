{
  lib,
  callPackage,
  fetchFromGitHub,
  symlinkJoin,
}: let
  # One version, one tag, one source tree for both halves. The desktop app is
  # not built from this checkout — Electrobun pulls a bun runtime and a webview
  # shim over the network — so it takes the .deb this same tag released, and
  # the tag is what keeps the two in step.
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "pounce-ai";
    repo = "pounce";
    tag = "v${version}";
    hash = "sha256-d5KJb4XjoLJoKskL0dko+p+TKkmE+KdyJtNLm01s0/8=";
  };

  cli = callPackage ./cli.nix {inherit version src;};
  desktop = callPackage ./desktop.nix {inherit version;};
in
  symlinkJoin {
    name = "pounce-${version}";
    paths = [cli desktop];

    passthru = {
      inherit cli desktop version src;
    };

    meta = {
      description = "Control your coding agents from your phone: bridge CLI plus the Linux desktop app";
      homepage = "https://use-pounce.com";
      license = lib.licenses.mit;
      maintainers = [];
      platforms = lib.platforms.linux;
      mainProgram = "pounce";
    };
  }
