{
  fetchFromGitHub,
  rustPlatform,
}: let
  version = "0.1.0-beta.6";

  src = fetchFromGitHub {
    owner = "chicagobuss";
    repo = "crusteo";
    tag = "v${version}";
    hash = "sha256-9+BqFN1GjlW4QnqUvFT4yH8yI6bPlRqyzlmWXx4KwP4=";
  };
in {
  inherit version src;

  # One vendor tree for the whole workspace, so crusteo, crusteo-reef and
  # crusteo-burrow cannot disagree about a dependency.
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "crusteo-${version}";
    hash = "sha256-HtvoNyDPP8N10Y+G43xFzeczCV1XeAxgpitH6Ds6Xvg=";
  };
}
