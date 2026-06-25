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
  version = "0.15.1";

  src = fetchFromGitHub {
    owner = "solidtime-io";
    repo = "solidtime";
    tag = "v${finalAttrs.version}";
    hash = "sha256-xfI647a/C/JdH88LDk3E8uIYdgRZl+nxSSwggyFI0Fg=";
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

  vendorHash = "sha256-v4kQNEuduJKbnkDv2a1cwYcmLmJGRii+J2F3jlAwX18=";
  composerNoPlugins = false;

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-qSr5kl+5QXLwZRccGPTfMqj7zjtzuzJKPqYj5Wr1RD0=";
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
