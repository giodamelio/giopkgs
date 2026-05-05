{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  makeWrapper,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "mcporter";
  version = "0.10.1";

  src = fetchFromGitHub {
    owner = "steipete";
    repo = "mcporter";
    rev = "v${finalAttrs.version}";
    hash = "sha256-MaIduY59Q2zVZheN1IYhAWBklQ3n6iJV3KiTMHCML2U=";
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
    makeWrapper
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-jqHEu86dNjJuYBVKDeDlre+KlFEqx55YXZ5K81AK+uY=";
  };

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/mcporter
    cp -r . $out/lib/node_modules/mcporter

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/mcporter \
      --add-flags $out/lib/node_modules/mcporter/dist/cli.js

    runHook postInstall
  '';

  meta = {
    description = "TypeScript runtime and CLI for connecting to configured Model Context Protocol servers";
    homepage = "https://github.com/steipete/mcporter";
    changelog = "https://github.com/steipete/mcporter/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [giodamelio];
    mainProgram = "mcporter";
    platforms = lib.platforms.all;
  };
})
