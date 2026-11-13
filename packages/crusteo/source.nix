{
  fetchFromGitHub,
  rustPlatform,
}: let
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "chicagobuss";
    repo = "crusteo";
    tag = "v${version}";
    hash = "sha256-P9VEzrRQgpqrlQjXKvwmQ6pxDk0YaCtI1QpmT4Vnk/g=";
  };
in {
  inherit version src;

  # One vendor tree for the whole workspace, so crusteo, crusteo-reef and
  # crusteo-burrow cannot disagree about a dependency.
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "crusteo-${version}";
    hash = "sha256-dyr5DwizwW7o0xrViS46bPaNZ3SdE4L/DUuCaSWVDS0=";
  };
}
