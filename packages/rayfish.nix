{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    tag = "v${version}";
    hash = "sha256-Sn8sYTi3oBUX+FvIBjpIgQ5QUwNO3pWXeG06RNkhySw=";
  };

  cargoHash = "sha256-JcFaWYhgf8LzoriHmMwEYerQ1leAeog4+uuRQ4Uwunc=";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
