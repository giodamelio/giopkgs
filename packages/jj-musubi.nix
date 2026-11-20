{
  lib,
  rustPlatform,
  fetchFromGitHub,
  git,
  openssh,
}:
rustPlatform.buildRustPackage rec {
  pname = "jj-musubi";
  version = "0.47.1";

  src = fetchFromGitHub {
    owner = "bos";
    repo = "jj-musubi";
    tag = "v${version}";
    hash = "sha256-hiQDJf6/08SDCNxs+vN7zC/EF+te/vf2Swi0HP7mfaY=";
  };

  cargoHash = "sha256-gliTi21j3XqIMc7udbnMnU1JNu7SU9DsepeePG3jBXI=";

  buildAndTestSubdir = "crates/musubi";

  nativeCheckInputs = [
    git
    openssh
  ];

  # tests/ needs a jj on PATH of exactly the version musubi pins jj-lib to, which nixpkgs
  # usually lags behind.
  # REMIND-ME-TO: run tests/ again with jujutsu in nativeCheckInputs nixpkg_version=jujutsu@>=0.47.1
  cargoTestFlags = ["--bins"];

  checkFlags = [
    # Compares against an oracle built from the Lean models in formal/, which needs lake.
    "--skip=copy::conformance::decisions_conformance"
    # Its stand-in sudo dispatches on /bin/cp, /bin/rm and /bin/test, absent in the sandbox.
    "--skip=login::process_tests::service_installation_tracks_success_and_keeps_services_separate"
  ];

  meta = {
    description = "Keep jj repos in sync across your machines, live";
    homepage = "https://github.com/bos/jj-musubi";
    license = lib.licenses.asl20;
    maintainers = [];
    mainProgram = "musubi";
  };
}
