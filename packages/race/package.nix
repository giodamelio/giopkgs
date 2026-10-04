{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libGL,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  vulkan-loader,
  wayland,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "race";
  version = "1.1.6";

  # The unversioned RACE-Linux-x86_64.tar.gz on the site is rebuilt in place, so
  # pin the per-release copy.
  src = fetchurl {
    url = "https://downloads.race-term.com/releases/v${finalAttrs.version}/RACE-Linux-x86_64.tar.gz";
    hash = "sha256-JaG69vpNXSxeAW35H3rQnFjfJfrF1g/CIspUIuDOrpk=";
  };

  nativeBuildInputs = [autoPatchelfHook];

  # winit and wgpu dlopen these, so autoPatchelfHook cannot see them in DT_NEEDED.
  runtimeDependencies = [
    libGL
    libx11
    libxcb
    libxcursor
    libxi
    libxkbcommon
    vulkan-loader
    wayland
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 -t $out/bin race race-control race-mcp
    install -Dm644 race.png $out/share/icons/hicolor/1024x1024/apps/race.png
    install -Dm644 race.desktop $out/share/applications/race.desktop
    install -Dm644 EULA.txt $out/share/doc/race/EULA.txt

    runHook postInstall
  '';

  meta = {
    description = "Terminal multiplexer on an infinite, zoomable canvas";
    homepage = "https://race-term.com";
    changelog = "https://race-term.com/changelog/";
    license = lib.licenses.unfree;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    maintainers = [];
    platforms = ["x86_64-linux"];
    mainProgram = "race";
  };
})
