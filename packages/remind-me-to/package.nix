{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "remind-me-to";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "giodamelio";
    repo = "remind-me-to";
    rev = "5fb3a5cb89a927c207a6bb416136d76504f93d96";
    hash = "sha256-YMHxViHchFdKhdIMvNnN2Mh7wneOo+TizbtXCYskUI0=";
  };

  cargoHash = "sha256-OgN6c3ujLwHVA9wqg7GeBS4xkJqzehLw1MUlefFhfI0=";

  doCheck = false;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "A command-line reminder tool";
    homepage = "https://github.com/giodamelio/remind-me-to";
    license = lib.licenses.unfree; # No license file in repository
    maintainers = [];
    mainProgram = "remind-me-to";
  };
}
