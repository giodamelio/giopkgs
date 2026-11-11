{
  lib,
  callPackage,
  rustPlatform,
  pname,
  cargoPackage,
  mainProgram,
  description,
}: let
  source = callPackage ./source.nix {};
in
  rustPlatform.buildRustPackage {
    inherit pname;
    inherit (source) version src cargoDeps;

    cargoBuildFlags = ["--package=${cargoPackage}"];
    cargoTestFlags = ["--package=${cargoPackage}"];

    # build.rs falls back to `git rev-parse`, which the store tree cannot answer.
    env.CRUSTEO_COMMIT = "v${source.version}";

    # The tests spawn daemons on loopback ports and drive them over WebSockets.
    doCheck = false;

    # packages/crusteo/update.nu moves this with the rest of the workspace.
    passthru.updatePolicy = "skip";

    meta = {
      inherit description mainProgram;
      homepage = "https://github.com/chicagobuss/crusteo";
      changelog = "https://github.com/chicagobuss/crusteo/releases/tag/v${source.version}";
      license = lib.licenses.asl20;
      maintainers = [];
    };
  }
