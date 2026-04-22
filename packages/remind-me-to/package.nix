{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "remind-me-to";
  version = "0-unstable-2026-04-22";

  src = fetchFromGitHub {
    owner = "giodamelio";
    repo = "remind-me-to";
    rev = "c5e778d54ccd932301aeca2f7238126bcf9e52b3";
    hash = "sha256-MYuWuSIbcAB6oaUhlvHQNAatn9ddECxh7hFlAIfBxFs=";
  };

  cargoHash = "sha256-eftfZdAuzwggpZPqnVnmiLXQj2r7BiOTygijCmlN13Q=";

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
