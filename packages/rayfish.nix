{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  # Tracks the tip of passthru.updateBranch on our fork rather than a tagged release.
  # nix-update (branch mode) bumps rev/version/hash automatically.
  version = "0-unstable-2026-09-25";

  src = fetchFromGitHub {
    owner = "giodamelio";
    repo = "rayfish";
    rev = "fcc98a144ba0b91229de4f520fa9416649ae0535";
    hash = "sha256-YeUwqE4/8R/T8W9bQh/4BxAHmwFilRsYeV2axE76eGw=";
  };

  cargoHash = "sha256-ZstoSf0VEArkhZfTPx/7WEUuAYFSrxEkm5avRT5/bcc=";

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
    "--skip=ssh::tests::keepalives_preserve_idle_sessions_and_close_unresponsive_clients"
    "--skip=ssh::tests::session_env_takes_locale_and_drops_the_rest"
    # Uses uid 1000 as its unprivileged caller and reads the config without
    # holding CONFIG_ENV_LOCK. The sandbox build user is also uid 1000, so a
    # concurrent test that makes the current euid the operator races it.
    "--skip=daemon::net_config_authz_tests::net_config_set_is_a_mutation_and_net_config_get_is_an_open_read"
  ];

  passthru = {
    updatePolicy = "branch";
    updateBranch = "network-flow-labels";
  };

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    maintainers = [];
    mainProgram = "ray";
  };
}
