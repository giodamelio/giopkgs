{
  lib,
  rustPlatform,
  fetchFromGitHub,
  git,
  jujutsu,
}:
rustPlatform.buildRustPackage rec {
  pname = "jj-worktree";
  version = "0.2.4";

  src = fetchFromGitHub {
    owner = "kawaz";
    repo = "jj-worktree";
    tag = "v${version}";
    hash = "sha256-gnezQ9P6syy5FXfLVuUS4ZmjnKojPYz8PFxw8XrRgSo=";
  };

  cargoHash = "sha256-rPmCpIZ3bm45ZNdPtpgTxQJQlV7fTlbvyXjORGaO1Ds=";

  nativeCheckInputs = [
    git
    jujutsu
  ];

  meta = {
    description = "Git shim that translates worktree operations to jj workspace commands";
    homepage = "https://github.com/kawaz/jj-worktree";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "jj-worktree";
  };
}
