{
  fetchFromGitHub,
  rustPlatform,
}: let
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "chicagobuss";
    repo = "crusteo";
    tag = "v${version}";
    hash = "sha256-U6xRVPKdOIn0gkPxUdjkj6fgti+ao7SXO9H6+6Im/ck=";
  };
in {
  inherit version src;

  # One vendor tree for the whole workspace, so crusteo, crusteo-reef and
  # crusteo-burrow cannot disagree about a dependency.
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "crusteo-${version}";
    hash = "sha256-xBA+CcH+lO+LZwrorhAm5x23Uc9RBtRnPcY2jopBm6w=";
  };
}
