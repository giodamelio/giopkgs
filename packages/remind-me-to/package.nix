{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "remind-me-to";
  version = "0-unstable-2026-04-21";

  src = fetchFromGitHub {
    owner = "giodamelio";
    repo = "remind-me-to";
    rev = "6397dba4d58c2a1a528965d0aeacce4b9e377c36";
    hash = "sha256-d0m7c0DeTfgFLZXZpJcqqF6F7uzMlz0yRee7aylkExE=";
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
