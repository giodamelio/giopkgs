# oh-my-pi (omp) package
# Build from source using bun + nightly rust
{
  lib,
  stdenv,
  fetchFromGitHub,
  makeRustPlatform,
  callPackage,
  bun,
  makeWrapper,
  pkg-config,
  openssl,
  wayland,
  wayland-protocols,
  libxkbcommon,
  # Nightly Rust via inline fenix import
  # Package version and hashes
  ompHashes ? builtins.fromJSON (builtins.readFile ./hashes.json),
  node_modules ? callPackage ./node-modules.nix {inherit ompHashes;},
}: let
  # Import fenix for nightly Rust toolchain
  fenixSrc = fetchFromGitHub {
    owner = "nix-community";
    repo = "fenix";
    inherit (ompHashes.fenix) rev hash;
  };
  fenix = import fenixSrc {inherit (stdenv.hostPlatform) system;};

  # Use nightly toolchain for edition 2024 and nightly features
  rustToolchain = fenix.complete.toolchain;

  rustPlatform = makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };

  platform = stdenv.hostPlatform;
  targetPlatform =
    if platform.isLinux
    then "linux"
    else "darwin";
  targetArch =
    if platform.isAarch64
    then "arm64"
    else "x64";
  # For x64, use baseline variant for wider CPU compatibility
  nodeFileName = "pi_natives.${targetPlatform}-${targetArch}${
    if targetArch == "x64"
    then "-baseline"
    else ""
  }.node";
  # bun compile target (e.g., bun-linux-x64-modern)
  bunTarget = "bun-${targetPlatform}-${targetArch}${
    if targetArch == "x64"
    then "-modern"
    else ""
  }";

  src = fetchFromGitHub {
    inherit (ompHashes) owner repo rev;
    hash = ompHashes.srcHash;
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    hash = ompHashes.cargoHash;
  };
in
  stdenv.mkDerivation {
    pname = "omp";
    inherit (ompHashes) version;
    inherit src;

    nativeBuildInputs = [
      bun
      makeWrapper
      pkg-config
      rustPlatform.cargoSetupHook
      rustToolchain
    ];

    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      openssl
      wayland
      wayland-protocols
      libxkbcommon
    ];

    inherit cargoDeps;

    postPatch = ''
      # Copy node_modules from FOD
      cp -R ${node_modules}/. .
      chmod -R +w .

      # Patch version in package.json files to use our version (git short hash)
      # This ensures the binary reports the correct version when built from non-release commits
      for pkg in packages/*/package.json; do
        if [ -f "$pkg" ]; then
          sed -i 's/"version": "[^"]*"/"version": "${ompHashes.version}"/' "$pkg"
        fi
      done
    '';

    env = {
      TARGET_PLATFORM = targetPlatform;
      TARGET_ARCH = targetArch;
      # Skip AVX2 detection, use baseline for compatibility
      TARGET_VARIANT = "baseline";
    };

    buildPhase = ''
      runHook preBuild

      export HOME=$(mktemp -d)

      # 1. Build Rust native addon
      echo "Building pi-natives..."
      cd crates/pi-natives
      cargo build --release
      cd ../..

      # 2. Copy the built library to the expected location
      mkdir -p packages/natives/native
      cp target/release/libpi_natives.so packages/natives/native/${nodeFileName}

      # 3. Embed the native addon into TypeScript source
      echo "Embedding native addon..."
      bun --cwd packages/natives scripts/embed-native.ts

      # 4. Generate docs index
      echo "Generating docs index..."
      bun --bun --cwd packages/coding-agent scripts/generate-docs-index.ts

      # 5. Build stats client bundle (optional - may fail in sandbox)
      echo "Building stats client bundle..."
      bun --bun --cwd packages/stats scripts/generate-client-bundle.ts || echo "Stats bundle build failed, continuing..."

      # 6. Compile the binary
      echo "Compiling omp binary..."
      bun build --compile \
        --target=${bunTarget} \
        --define PI_COMPILED=true \
        --root . \
        ./packages/coding-agent/src/cli.ts \
        --outfile dist/omp

      runHook postBuild
    '';

    # Don't strip the binary - bun compile embeds code that might be affected
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 dist/omp $out/bin/omp
      wrapProgram $out/bin/omp \
        --set PI_SKIP_VERSION_CHECK 1

      runHook postInstall
    '';

    meta = {
      description = "Oh My Pi - AI coding agent CLI";
      homepage = "https://github.com/${ompHashes.owner}/${ompHashes.repo}";
      license = lib.licenses.mit;
      mainProgram = "omp";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  }
