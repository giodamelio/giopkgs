{
  runCommand,
  curl,
  tlbx,
}:
# `mt --version` is not enough on its own: it answers from a version baked into
# the binary without touching TLS, so it passed cleanly on a build whose libssl
# could not be dlopened. Starting the server generates a self-signed certificate
# and opens an HTTPS listener, which is what actually exercises openssl.
runCommand "tlbx-startup-test" {
  nativeBuildInputs = [curl tlbx];

  # The sandbox has no network. mt's update check will fail and log, but it runs
  # after the listener is up, so it does not affect this test.
  MIDTERM_SETTINGS_DIR = "settings";
} ''
  export HOME=$PWD

  reported=$(mt --version)
  if [ "$reported" != "${tlbx.version}" ]; then
    echo "mt --version reported '$reported', expected '${tlbx.version}'" >&2
    exit 1
  fi

  mt --port 28080 --bind 127.0.0.1 > server.log 2>&1 &
  server=$!
  trap 'kill $server 2>/dev/null' EXIT

  ready=
  for _ in $(seq 1 60); do
    if curl -sk --fail -o index.html https://127.0.0.1:28080/; then
      ready=1
      break
    fi
    sleep 1
  done

  if [ -z "$ready" ]; then
    echo "tlbx never answered on https://127.0.0.1:28080/" >&2
    cat server.log >&2
    exit 1
  fi

  if ! grep -qi '<!doctype html>' index.html; then
    echo "tlbx answered but did not serve its app:" >&2
    head -c 500 index.html >&2
    exit 1
  fi

  touch $out
''
