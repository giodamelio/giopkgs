{callPackage}:
callPackage ../crusteo/headless.nix {
  pname = "crusteo-burrow";
  cargoPackage = "burrow-daemon";
  mainProgram = "burrow";
  description = "Crusteo's coding-agent daemon, speaking the Paseo WebSocket protocol";
}
