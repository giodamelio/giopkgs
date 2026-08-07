{
  php83,
  fetchFromGitHub,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  lib,
}:
php83.buildComposerProject2 (finalAttrs: {
  pname = "solidtime";
  version = "0.19.1";

  src = fetchFromGitHub {
    owner = "solidtime-io";
    repo = "solidtime";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1iBbFnMRHinFiY6t2enA9QCts5z4xq1Ui4LMNxtMM4M=";
  };

  php = php83.buildEnv {
    extensions = {
      enabled,
      all,
    }:
      enabled
      ++ (with all; [
        bcmath
        exif
        gd
        intl
        mbstring
        pdo
        pdo_pgsql
        pdo_mysql
        tokenizer
        zip
      ]);
  };

  vendorHash = "sha256-ce97eNDw+1dXJROnYCTQX1csrHsk9aLBAFIokqaxDQ0=";
  composerNoPlugins = false;

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-X4xJZ7ieB8cmrcfMacxQShdhDvvXJSj1SC+RhrnB7e4=";
  };

  nativeBuildInputs = [
    nodejs
    npmHooks.npmConfigHook
  ];

  # Build frontend assets after composer vendor is installed
  postBuild = ''
    npx vite build
  '';

  postInstall = ''
    # Copy the built frontend assets
    cp -r public/build "$out"/share/php/${finalAttrs.pname}/public/build

    # Create artisan console wrapper
    mkdir -p "$out"/bin
    ln -s "$out"/share/php/${finalAttrs.pname}/artisan "$out"/bin/artisan
  '';

  meta = {
    description = "Modern open-source time tracking application";
    homepage = "https://github.com/solidtime-io/solidtime";
    license = lib.licenses.agpl3Plus;
    maintainers = [];
    platforms = lib.platforms.all;
  };
})
