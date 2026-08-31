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
  version = "0.20.0";

  src = fetchFromGitHub {
    owner = "solidtime-io";
    repo = "solidtime";
    tag = "v${finalAttrs.version}";
    hash = "sha256-grLNwy7DvaZSyO6kvCLa7WEkn88O8Xm8qha7SGPOhHY=";
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

  vendorHash = "sha256-OHP8o750szwVg8SxY7ztReOa8YZNTsws1jTRoY7p8EA=";
  composerNoPlugins = false;

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-HdPYn9crPeMei5yhWiM1BK/GrNGLP2wHE9M/6RGi4W4=";
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
