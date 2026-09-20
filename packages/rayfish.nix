{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of the upstream default branch rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "nightly-unstable-2026-09-23";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "9f19d875f82acaf51599c64fb2346994bebc62e4";
    hash = "sha256-o5Run5jUIcDFwTRZ1T3rm9/c/33YH3XnoVTq14ZjIU4=";
  };

  cargoHash = "sha256-bcIYlEWxh7v0zgRSEBHC0G/+5mcFRR8bjg8aooO0SNE=";

  # The CLI colorizes when stdout is a terminal, and Nix runs the builder on a
  # pty — so the renderer tests, which assert on unstyled text, see ANSI escapes
  # here but not in a piped CI run.
  preCheck = ''
    export NO_COLOR=1
  '';

  # These spawn a real session shell for the build user, taken from its passwd
  # entry. The sandbox gives nixbld `/noshell`, and /etc/passwd is read-only, so
  # the child never execs and every assertion sees empty output.
  checkFlags = [
    "--skip=ssh::tests::a_session_knows_it_is_remote"
    "--skip=ssh::tests::a_signal_request_reaches_the_session_process"
    "--skip=ssh::tests::agent_forwarding_hands_the_session_a_socket_that_reaches_the_client"
    "--skip=ssh::tests::an_authenticated_session_outlives_the_login_grace"
    "--skip=ssh::tests::concurrent_channels_keep_their_own_output_and_pty"
    "--skip=ssh::tests::every_channel_on_one_connection_runs_its_command"
    "--skip=ssh::tests::session_env_takes_locale_and_drops_the_rest"
  ];

  passthru.updatePolicy = "branch";

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
