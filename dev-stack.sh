#!/usr/bin/env bash
# TEMPORARY manual test harness for the crw-camofox stack. Not wired into the
# flake, not run by CI — delete it once the NixOS service exists.
#
#   crw-server ──HTTP──▶ camofox-browser ──camoufox-js──▶ camoufox (prebuilt)
#
# crw talks to the browser over REST only, so the two are independent processes
# joined by a URL. Everything either writes lives under a scratch dir that is
# removed on exit.
#
#   ./dev-stack.sh                 # start the stack, wait for Ctrl-C
#   CRW_PORT=4000 ./dev-stack.sh   # override ports
#   KEEP_STATE=1 ./dev-stack.sh    # leave the scratch dir behind for poking at
set -euo pipefail

CAMOUFOX_NIX=${CAMOUFOX_NIX:-github:giodamelio/camoufox-nix/add-camoufox-bin}
# The fork, not upstream. Upstream has its own opt-in Camoufox tier, but spelled
# `camoufox`/[renderer.camoufox] and default-off — and the crw package here
# matches upstream's Docker build (cdp,impersonated), so it is compiled without
# it. Pointing CRW_ATTR at crw would start fine and ignore camofox-browser.
CRW_ATTR=${CRW_ATTR:-crw-camofox}
CRW_PORT=${CRW_PORT:-3000}
CAMOFOX_PORT=${CAMOFOX_PORT:-9377}

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
state=$(mktemp -d /tmp/crw-stack-XXXXXX)

cleanup() {
  [[ -n ${crw_pid:-} ]] && kill "$crw_pid" 2>/dev/null || true
  [[ -n ${cfx_pid:-} ]] && kill "$cfx_pid" 2>/dev/null || true
  wait 2>/dev/null || true
  if [[ -n ${KEEP_STATE:-} ]]; then
    echo "state kept at $state"
  else
    rm -rf "$state"
  fi
}
trap cleanup EXIT INT TERM

wait_for() {
  local name=$1 url=$2 pid=$3 log=$4
  for _ in $(seq 1 120); do
    curl -fsS "$url" >/dev/null 2>&1 && return 0
    kill -0 "$pid" 2>/dev/null || { echo "$name died:"; tail -30 "$log"; return 1; }
    sleep 1
  done
  echo "$name never became healthy:"; tail -30 "$log"; return 1
}

echo "==> building crw ($CRW_ATTR) — expect ~12 min cold, instant once cached"
crw=$(nix build --no-link --print-out-paths "$repo#$CRW_ATTR")

echo "==> building camofox-browser wired to camoufox-bin"
# camoufox-bin's passthru carries a bin-wired variant of every camoufox tool,
# which is what keeps this a download instead of a full Firefox compile.
#
# This launches camoufox-nix's OWN pin (150.0.2-beta.25), not the 152.0.4-beta.29
# in packages/camoufox-bin. To point it at that one instead, export
# CAMOUFOX_EXECUTABLE — the wrapper reads it before its baked-in default — but
# camoufox-js validates the browser version against a CONSTRAINTS range, so a
# 150 -> 152 jump may be refused.
cfx=$(nix build --no-link --print-out-paths "$CAMOUFOX_NIX#camoufox-bin.camofox-browser")

mkdir -p "$state/home" "$state/run"
cp "$crw/share/$CRW_ATTR/config.default.toml" "$state/run/"

echo "==> starting camofox-browser on 127.0.0.1:$CAMOFOX_PORT"
env -i \
  PATH="/usr/bin:/bin" \
  HOME="$state/home" \
  XDG_CACHE_HOME="$state/home/.cache" \
  XDG_CONFIG_HOME="$state/home/.config" \
  CAMOFOX_HOST=127.0.0.1 \
  CAMOFOX_PORT="$CAMOFOX_PORT" \
  CAMOFOX_AUTH_MODE=disabled \
  CAMOFOX_ALLOW_PRIVATE_NETWORK=false \
  "$cfx/bin/camofox-browser" >"$state/camofox.log" 2>&1 &
cfx_pid=$!
wait_for camofox-browser "http://127.0.0.1:$CAMOFOX_PORT/health" "$cfx_pid" "$state/camofox.log"

echo "==> starting crw-server on 127.0.0.1:$CRW_PORT"
cd "$state/run"
env -i \
  PATH="/usr/bin:/bin" \
  HOME="$state/home" \
  RUST_LOG="${RUST_LOG:-info}" \
  CRW_SERVER__HOST=127.0.0.1 \
  CRW_SERVER__PORT="$CRW_PORT" \
  CRW_RENDERER__MODE=auto \
  CRW_RENDERER__CAMOFOX__BASE_URL="http://127.0.0.1:$CAMOFOX_PORT" \
  CRW_SEARCH__TIMEOUT_MS="${CRW_SEARCH_TIMEOUT_MS:-45000}" \
  "$crw/bin/crw-server" >"$state/crw.log" 2>&1 &
crw_pid=$!
wait_for crw-server "http://127.0.0.1:$CRW_PORT/health" "$crw_pid" "$state/crw.log"

cat <<EOF

==> stack up
    crw              http://127.0.0.1:$CRW_PORT
    camofox-browser  http://127.0.0.1:$CAMOFOX_PORT
    logs             $state/{crw,camofox}.log

    curl -s localhost:$CRW_PORT/ready | jq

    curl -s localhost:$CRW_PORT/v1/scrape -H 'content-type: application/json' \\
      -d '{"url":"https://example.com","formats":["markdown"]}' | jq -r .data.markdown

    # forces the camofox tier rather than letting the ladder pick
    curl -s localhost:$CRW_PORT/v1/scrape -H 'content-type: application/json' \\
      -d '{"url":"https://example.com","renderer":"camofox"}' | jq .data.renderDecision

    # browser-driven search — the thing the fork adds over upstream
    curl -s localhost:$CRW_PORT/v1/search -H 'content-type: application/json' \\
      -d '{"query":"nixos camoufox","limit":3}' | jq -r '.data[]?.url'

Ctrl-C to tear down.
EOF

tail -f "$state/crw.log" "$state/camofox.log" &
wait "$crw_pid"
