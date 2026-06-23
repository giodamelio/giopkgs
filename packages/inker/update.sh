#!/usr/bin/env bash
# Custom updater for inker.
#
# Inker can't use plain nix-update because:
#   * its committed package-lock.json files are stale (the real lockfile is
#     bun.lock), so we regenerate fresh npm lockfiles and vendor them here, and
#   * the pinned Prisma engine binaries are version-locked to a commit hash that
#     is derived from the regenerated backend lockfile.
#
# This script recomputes everything from the latest upstream tag and rewrites
# package.nix in place. It is idempotent: run on an already-current package it
# produces no changes.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$DIR/package.nix"
FLAKE="$DIR/../.."
OWNER="usetrmnl"
REPO="inker"

NIXPKGS=("jq" "nurl" "nodejs" "prefetch-npm-deps")
shell() { nix shell "${NIXPKGS[@]/#/nixpkgs#}" --command "$@"; }

echo ">> Resolving latest tag"
latest="$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/tags" | shell jq -r '.[0].name')"
echo "   $latest"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo ">> Regenerating npm lockfiles"
for app in frontend backend; do
  mkdir -p "$work/$app"
  curl -fsSL "https://raw.githubusercontent.com/$OWNER/$REPO/$latest/$app/package.json" \
    -o "$work/$app/package.json"
  ( cd "$work/$app"
    shell npm install --package-lock-only --ignore-scripts --legacy-peer-deps >/dev/null 2>&1 )
  cp "$work/$app/package-lock.json" "$DIR/$app-package-lock.json"
done

echo ">> Computing hashes"
srcHash="$(shell nurl "https://github.com/$OWNER/$REPO" "$latest" | grep -oP 'hash = "\K[^"]+')"
frontendDeps="$(shell prefetch-npm-deps "$DIR/frontend-package-lock.json" | tail -1)"
backendDeps="$(shell prefetch-npm-deps "$DIR/backend-package-lock.json" | tail -1)"

engineCommit="$(shell jq -r '.packages["node_modules/@prisma/engines-version"].version | split(".")[-1]' \
  "$DIR/backend-package-lock.json")"
echo "   prisma engine commit: $engineCommit"

engHash() {
  nix store prefetch-file --json \
    "https://binaries.prisma.sh/all_commits/$engineCommit/debian-openssl-3.0.x/$1.gz" \
    | shell jq -r '.hash'
}
queryLibHash="$(engHash libquery_engine.so.node)"
schemaHash="$(engHash schema-engine)"
queryHash="$(engHash query-engine)"

echo ">> Rewriting package.nix"
sed -i \
  -e "s|version = \"[^\"]*\";|version = \"$latest\";|" \
  -e "s|prismaEnginesCommit = \"[^\"]*\";|prismaEnginesCommit = \"$engineCommit\";|" \
  -e "/tag = version;/{n;s|hash = \"[^\"]*\"|hash = \"$srcHash\"|}" \
  -e "/frontend-package-lock.json;/{n;s|hash = \"[^\"]*\"|hash = \"$frontendDeps\"|}" \
  -e "/backend-package-lock.json;/{n;s|hash = \"[^\"]*\"|hash = \"$backendDeps\"|}" \
  -e "/prismaEngineUrl \"libquery_engine.so.node\";/{n;s|hash = \"[^\"]*\"|hash = \"$queryLibHash\"|}" \
  -e "/prismaEngineUrl \"schema-engine\";/{n;s|hash = \"[^\"]*\"|hash = \"$schemaHash\"|}" \
  -e "/prismaEngineUrl \"query-engine\";/{n;s|hash = \"[^\"]*\"|hash = \"$queryHash\"|}" \
  "$PKG"

echo ">> Done. Building to verify."
nix build "$FLAKE#inker"
