{
  lib,
  rustPlatform,
  fetchFromGitHub,
  perl,
}:

rustPlatform.buildRustPackage rec {
  pname = "mcp-proxy";
  version = "0.2.3";

  src = fetchFromGitHub {
    owner = "tidewave-ai";
    repo = "mcp_proxy_rust";
    rev = "v${version}";
    hash = "sha256-pU4a9cpMltu8dRkYtq/ge84RHLCqEDtbhItN7rarSOc=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "rmcp-0.8.1" = "sha256-jKxBi1dqnZk/qsEYrm2q2sU/ym62NYILQTug8xA24Ro=";
    };
  };

  # perl is needed to build vendored openssl
  nativeBuildInputs = [ perl ];

  # Tests require example binaries that aren't built
  doCheck = false;

  meta = {
    description = "A proxy to use HTTP/SSE MCPs from STDIO clients";
    homepage = "https://github.com/tidewave-ai/mcp_proxy_rust";
    changelog = "https://github.com/tidewave-ai/mcp_proxy_rust/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.unfree; # No license file in repository
    maintainers = with lib.maintainers; [ ];
    mainProgram = "mcp-proxy";
  };
}
