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
  version = "1.6.10";

  src = fetchFromGitHub {
    owner = "pounce-ai";
    repo = "pounce";
    tag = "v${version}";
    hash = "sha256-8syANoUiyHESqHPlLcyIEmYrGW9yAJ198YhBGhMLqwM=";
  };

  cli = callPackage ./cli.nix {inherit version src;};
  desktop = callPackage ./desktop.nix {inherit version;};

  # Out of `paths` deliberately: an APK is a file to copy to a phone, not
  # something with a bin/ to merge into a profile.
  apk = callPackage ./apk.nix {inherit version src;};
in
  symlinkJoin {
    name = "pounce-${version}";
    paths = [cli desktop];

    passthru = {
      inherit cli desktop apk version src;
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
