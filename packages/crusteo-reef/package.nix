{callPackage}:
callPackage ../crusteo/headless.nix {
  pname = "crusteo-reef";
  cargoPackage = "reef";
  mainProgram = "reef";
  description = "Headless Crusteo fleet service that serves the Skiff phone client";
}
