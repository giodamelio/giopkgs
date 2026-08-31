{
  rustPlatform,
  cmake,
  git,
}: {
  pname,
  version,
  src,
  cargoHash,
  buildFeatures,
  meta,
  passthru ? {},
}:
rustPlatform.buildRustPackage {
  inherit pname version src cargoHash buildFeatures meta passthru;

  # btls-sys (the vendored BoringSSL behind wreq, i.e. the `impersonated`
  # feature) drives CMake from its own build script and generates its bindings
  # with bindgen, which dlopens libclang. Letting the cmake setup hook configure
  # the workspace root would break the cargo build, hence dontUseCmakeConfigure.
  # git is for that same build script: it `git init`s the BoringSSL tree before
  # applying its patches.
  nativeBuildInputs = [cmake git rustPlatform.bindgenHook];
  dontUseCmakeConfigure = true;

  cargoBuildFlags = ["-p" "crw-server" "-p" "crw-mcp" "-p" "crw-cli"];

  # The workspace release profile is fat LTO at codegen-units = 1, whose final
  # link of crw-server (aws-lc-sys plus the whole dep graph) needs several GB
  # and OOM-kills smaller builders. Upstream's own Docker image relaxes it the
  # same way; the runtime difference is negligible.
  env = {
    CARGO_PROFILE_RELEASE_LTO = "thin";
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16";
  };

  # The test suite drives live browsers and the network.
  doCheck = false;

  # `AppConfig::load` reads `config.default.toml` from the *working directory*,
  # not from the binary's prefix, so this is a reference copy to point $CRW_CONFIG
  # at — the same files the Docker image drops into /app.
  postInstall = ''
    install -Dm444 -t $out/share/${pname} config.*.toml
  '';
}
