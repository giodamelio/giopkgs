{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  stdenv,
  makeWrapper,
}: let
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "SawyerHood";
    repo = "dev-browser";
    tag = "v${version}";
    hash = "sha256-PRd6e5RN4wQ43qdNtPCtAIZ5RZOHn6UD8aYxJOfe7RA=";
  };

  daemon = stdenv.mkDerivation {
    pname = "dev-browser-daemon";
    inherit version src;

    sourceRoot = "${src.name}/daemon";

    nativeBuildInputs = [
      nodejs
      pnpmConfigHook
      pnpm_10
    ];

    pnpmDeps = fetchPnpmDeps {
      pname = "dev-browser-daemon";
      inherit version src;
      sourceRoot = "${src.name}/daemon";
      pnpm = pnpm_10;
      fetcherVersion = 3;
      hash = "sha256-TnIhWHniLYMeL0lGbSjz+aqcOYQOhVwDmUkrZJ5FquI=";
    };

    buildPhase = ''
      runHook preBuild
      pnpm run bundle
      pnpm run bundle:sandbox-client
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp dist/daemon.bundle.mjs $out/
      cp dist/sandbox-client.js $out/
      runHook postInstall
    '';
  };
in
  rustPlatform.buildRustPackage {
    pname = "dev-browser";
    inherit version src;

    cargoRoot = "cli";
    buildAndTestSubdir = "cli";
    cargoHash = "sha256-pZGH5qRX9ylELvpL8MPxTL0cyaWWyH4gAsuroKYa9VE=";

    nativeBuildInputs = [makeWrapper];

    preBuild = ''
      mkdir -p daemon/dist
      cp ${daemon}/daemon.bundle.mjs daemon/dist/
      cp ${daemon}/sandbox-client.js daemon/dist/
    '';

    postInstall = ''
      wrapProgram $out/bin/dev-browser \
        --prefix PATH : ${lib.makeBinPath [nodejs]}
    '';

    meta = {
      description = "CLI for controlling browsers with sandboxed JavaScript scripts";
      homepage = "https://github.com/SawyerHood/dev-browser";
      license = lib.licenses.mit;
      maintainers = [];
      mainProgram = "dev-browser";
    };
  }
