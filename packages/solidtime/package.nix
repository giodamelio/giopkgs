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
  version = "0.21.0";

  src = fetchFromGitHub {
    owner = "solidtime-io";
    repo = "solidtime";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QlU8oRgzil7cewAR/FFh37H7p7n8ohDT4TBVk7u80FM=";
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

  vendorHash = "sha256-Gl3uIy2eg8fhvvNVncb+9PD5KB77EhYaRrJYp6cIk0k=";
  composerNoPlugins = false;

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-hBqYBC8vKbAj6WMq6sHTUpDwYxXnMkhjX5bLRYDAWlk=";
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
