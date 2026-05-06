{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "remind-me-to";
  version = "0-unstable-2026-04-25";

  src = fetchFromGitHub {
    owner = "giodamelio";
    repo = "remind-me-to";
    rev = "be4c84727dc4d8fe9f68dea3c83f1d7559b38cd7";
    hash = "sha256-cs85Dy8PJQrXnlqMY60FI9YSsYd2uWZj1UNahULIx3k=";
  };

  cargoHash = "sha256-pNbN5IVixE4myo70a19a1k1V5q3kCBO7pAfYw0jytmg=";

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
