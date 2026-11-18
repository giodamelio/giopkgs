{
  fetchFromGitHub,
  rustPlatform,
}: let
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "chicagobuss";
    repo = "crusteo";
    tag = "v${version}";
    hash = "sha256-lWIOjr4WbPXZ5z+42qWxb9zte3Je5XcwcB/MpGGJ6Pk=";
  };
in {
  inherit version src;

  # One vendor tree for the whole workspace, so crusteo, crusteo-reef and
  # crusteo-burrow cannot disagree about a dependency.
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "crusteo-${version}";
    hash = "sha256-Jd2VAGV68azXbTN2L+7XlqqVCsx1Ear9UUS4ANgg/lM=";
  };
}
