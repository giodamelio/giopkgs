{
  lib,
  rustPlatform,
  pkg-config,
  bzip2,
  sqlite,
  zstd,
  version,
  src,
  cargoHash,
}:
# The C-ABI library the Go SDK dlopens. Go programs built with
# `-tags microsandbox_ffi_path` read it from MICROSANDBOX_FFI_PATH instead of
# the prebuilt copy the tagged Go module embeds.
rustPlatform.buildRustPackage {
  pname = "microsandbox-go-ffi";
  inherit version src cargoHash;

  cargoBuildFlags = ["--package" "microsandbox-go"];

  # Default SDK features include download-binaries, which only gates the
  # build script that fetches the runtime bundle. Everything else is kept.
  postPatch = ''
    rm .cargo/config.toml
    substituteInPlace sdk/go/native/Cargo.toml \
      --replace-fail \
        'microsandbox = { workspace = true, default-features = true, features = ["net", "ssh"] }' \
        'microsandbox = { workspace = true, features = ["cloud", "keyring", "local", "net", "ssh"] }'
  '';

  env = {
    LIBSQLITE3_SYS_USE_PKG_CONFIG = "1";
    ZSTD_SYS_USE_PKG_CONFIG = "1";
  };

  nativeBuildInputs = [pkg-config];
  buildInputs = [bzip2 sqlite zstd];

  doCheck = false;

  postInstall = ''
    rm -f $out/lib/*.a
    install -Dm644 sdk/go/native/microsandbox_go_ffi.h -t $out/include
  '';

  meta = {
    description = "C-ABI library behind the microsandbox Go SDK";
    homepage = "https://github.com/superradcompany/microsandbox";
    license = lib.licenses.asl20;
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
