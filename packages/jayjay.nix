{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeBinaryWrapper,
  fontconfig,
  freetype,
  libxkbcommon,
  wayland,
  vulkan-loader,
  libGL,
  libxcb,
  jujutsu,
  xdg-utils,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "jayjay";
  version = "0.3.19";

  src = fetchFromGitHub {
    owner = "hewigovens";
    repo = "jayjay";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Cc8a10aOZ+wT6gnEAQ3QLmUEXCD0XRlegG4aU7M+yZg=";
  };

  cargoHash = "sha256-ENGj3LaP7ihmsHG1oLHen3A6zxRgoQrtSZT6RX5oOCc=";

  nativeBuildInputs = [
    pkg-config
    makeBinaryWrapper
  ];

  buildInputs = [
    fontconfig
    freetype
    libxkbcommon
    wayland
    libxcb
  ];

  cargoBuildFlags = ["--package=jayjay-gpui"];

  # The GPUI tests drive a window and shell out to the jj CLI against real repos.
  doCheck = false;

  postInstall = ''
    ln -s jayjay-gpui $out/bin/jayjay

    install -Dm644 shell/gpui/linux/dev.hewig.JayJay.desktop \
      $out/share/applications/dev.hewig.JayJay.desktop
    install -Dm644 shell/gpui/linux/dev.hewig.JayJay.metainfo.xml \
      $out/share/metainfo/dev.hewig.JayJay.metainfo.xml
    install -Dm644 docs/icon.svg \
      $out/share/icons/hicolor/scalable/apps/dev.hewig.JayJay.svg
  '';

  # GPU and display libraries are dlopened, so they never land in DT_NEEDED.
  postFixup = ''
    patchelf $out/bin/jayjay-gpui --add-rpath ${
      lib.makeLibraryPath [
        fontconfig
        libGL
        libxkbcommon
        vulkan-loader
        wayland
      ]
    }
    wrapProgram $out/bin/jayjay-gpui --suffix PATH : ${
      lib.makeBinPath [
        jujutsu
        xdg-utils
      ]
    }
  '';

  meta = {
    description = "Native desktop client for Jujutsu version control";
    homepage = "https://jayjay.hewig.dev/";
    changelog = "https://github.com/hewigovens/jayjay/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.bsl11;
    maintainers = with lib.maintainers; [];
    mainProgram = "jayjay-gpui";
    platforms = lib.platforms.linux;
  };
})
