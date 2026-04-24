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
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "solidtime-io";
    repo = "solidtime";
    tag = "v${finalAttrs.version}";
    hash = "sha256-qZ0NOrZoTuwOYZ7S407DIYcZAwbzCC+d+OqauQYiGgM=";
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

  vendorHash = "sha256-jnaendvJAVBF3MRH+XuBZ18f9kg0nzDrGKyWITJyvW0=";
  composerNoPlugins = false;

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-NiWxk6d2hnknP73lNpms9V5eU25DgKfV6FJWEb03oTE=";
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
