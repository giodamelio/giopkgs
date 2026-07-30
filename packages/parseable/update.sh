#!/usr/bin/env bash
# Custom updater for parseable.
#
# Plain nix-update can't handle this package because the prebuilt prism UI
# bundle is a third hash that nix-update knows nothing about. Its URL embeds
# the release version, so bumping version without refetching the zip leaves a
# stale hash and the build fails.
#
# Upstream's build.rs downloads that same zip and checks it against the
# assets-url/assets-sha1 pinned in Cargo.toml; LOCAL_ASSETS_PATH is upstream's
# own escape hatch for supplying it out-of-band. This script treats Cargo.toml
# as the source of truth and refuses to update if upstream ever decouples the
# UI version from the release version.
#
# Idempotent: run against an already-current package it makes no changes.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$DIR/package.nix"
FLAKE="$DIR/../.."
OWNER="parseablehq"
REPO="parseable"

NIXPKGS=("jq" "nurl")
shell() { nix shell "${NIXPKGS[@]/#/nixpkgs#}" --command "$@"; }

current="$(grep -oP 'version = "\K[^"]+' "$PKG")"
tag="$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | shell jq -r '.tag_name')"
latest="${tag#v}"

echo ">> current: $current, latest: $latest"
if [ "$current" = "$latest" ]; then
  echo ">> Already up to date."
  exit 0
fi

zip="$(mktemp)"
backup="$(mktemp)"
cp "$PKG" "$backup"
ok=false
# Any exit before `ok=true` restores package.nix, so a half-applied update or a
# blanked hash can never survive a failure.
trap '[ "$ok" = true ] || cp "$backup" "$PKG"; rm -f "$zip" "$backup"' EXIT

cargoToml="$(curl -fsSL "https://raw.githubusercontent.com/$OWNER/$REPO/$tag/Cargo.toml")"
assetsUrl="$(grep -oP 'assets-url = "\K[^"]+' <<<"$cargoToml")"
assetsSha1="$(grep -oP 'assets-sha1 = "\K[^"]+' <<<"$cargoToml")"
expectedUrl="https://parseable-prism-build.s3.us-east-2.amazonaws.com/v$latest/build.zip"

if [ "$assetsUrl" != "$expectedUrl" ]; then
  echo "Upstream UI asset URL no longer tracks the release version."
  echo "  Cargo.toml: $assetsUrl"
  echo "  expected:   $expectedUrl"
  echo "package.nix interpolates the version into the URL; it needs a manual fix."
  exit 1
fi

echo ">> Verifying prism bundle against upstream's pinned sha1"
curl -fsSL -o "$zip" "$assetsUrl"
actualSha1="$(sha1sum "$zip" | cut -d' ' -f1)"
if [ "$actualSha1" != "$assetsSha1" ]; then
  echo "Prism bundle sha1 mismatch (upstream pins $assetsSha1, got $actualSha1)."
  exit 1
fi

echo ">> Computing hashes"
srcHash="$(shell nurl "https://github.com/$OWNER/$REPO" "$tag" | grep -oP 'hash = "\K[^"]+')"
assetsHash="$(nix store prefetch-file --unpack --json --name source "$assetsUrl" | shell jq -r '.hash')"

sed -i \
  -e "s|version = \"[^\"]*\";|version = \"$latest\";|" \
  -e "/tag = \"v\${version}\";/{n;s|hash = \"[^\"]*\"|hash = \"$srcHash\"|}" \
  -e "/parseable-prism-build/{n;s|hash = \"[^\"]*\"|hash = \"$assetsHash\"|}" \
  -e "/inherit src;/{n;s|hash = \"[^\"]*\"|hash = \"\"|}" \
  "$PKG"

echo ">> Building vendor derivation to learn the cargo hash"
buildOutput="$(nix build "$FLAKE#parseable.cargoDeps" --no-link 2>&1 || true)"
cargoHash="$(grep -oP 'got:\s+\K\S+' <<<"$buildOutput" | head -1)"
if [ -z "$cargoHash" ]; then
  echo "Could not extract cargo vendor hash from build output:"
  tail -30 <<<"$buildOutput"
  exit 1
fi

sed -i "/inherit src;/{n;s|hash = \"\"|hash = \"$cargoHash\"|}" "$PKG"

echo ">> Updated to $latest. Building to verify."
if ! nix build "$FLAKE#parseable" --no-link; then
  echo "Build failed after update; reverting."
  exit 1
fi
ok=true
