{
  lib,
  callPackage,
  rustPlatform,
  pkg-config,
  fontconfig,
  freetype,
  libxkbcommon,
  wayland,
  vulkan-loader,
  libGL,
  libxcb,
  libx11,
}: let
  source = callPackage ./source.nix {};
in
  rustPlatform.buildRustPackage {
    pname = "crusteo";
    inherit (source) version src cargoDeps;

    nativeBuildInputs = [pkg-config];

    buildInputs = [
      fontconfig
      freetype
      libxkbcommon
      wayland
      libxcb
      libx11
    ];

    cargoBuildFlags = ["--package=crusteo"];
    cargoTestFlags = ["--package=crusteo"];

    # build.rs falls back to `git rev-parse`, which the store tree cannot answer.
    env.CRUSTEO_COMMIT = "v${source.version}";

    # The GPUI tests open windows.
    doCheck = false;

    postInstall = ''
      install -Dm644 assets/icon/crusteo.svg $out/share/icons/hicolor/scalable/apps/crusteo.svg
    '';

    # GPU and display libraries are dlopened, so they never land in DT_NEEDED.
    postFixup = ''
      patchelf $out/bin/crusteo --add-rpath ${
        lib.makeLibraryPath [
          fontconfig
          libGL
          libxkbcommon
          vulkan-loader
          wayland
        ]
      }
    '';

    meta = {
      description = "Native multi-host desktop client for Paseo coding-agent daemons";
      homepage = "https://github.com/chicagobuss/crusteo";
      changelog = "https://github.com/chicagobuss/crusteo/releases/tag/v${source.version}";
      license = lib.licenses.asl20;
      maintainers = [];
      mainProgram = "crusteo";
      platforms = lib.platforms.linux;
    };
  }
