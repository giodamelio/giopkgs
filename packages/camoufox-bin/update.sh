#!/usr/bin/env bash
# Regenerate sources.json for camoufox-bin from the latest GitHub release.
#
# nix-update can't handle this package: the release assets use inconsistent,
# per-platform version strings (e.g. lin.x86_64 is "alpha.26" while lin.arm64
# is "alpha.25" within the same "beta.25" tag), so each platform needs its own
# URL and hash. This script fetches the latest release, picks the Linux assets,
# prefetches their unpacked hashes, and writes sources.json.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="daijro/camoufox"

# Map a Camoufox asset arch suffix to a Nix system double.
declare -A SYSTEMS=(
  ["lin.x86_64"]="x86_64-linux"
  ["lin.arm64"]="aarch64-linux"
)

release="$(gh api "repos/${REPO}/releases/latest")"
tag="$(jq -r '.tag_name' <<<"$release")"
version="${tag#v}"

echo "Latest release: ${tag}" >&2

assets_json="{}"
for suffix in "${!SYSTEMS[@]}"; do
  system="${SYSTEMS[$suffix]}"
  url="$(jq -r --arg s "$suffix" \
    '.assets[] | select(.name | endswith("-" + $s + ".zip")) | .browser_download_url' \
    <<<"$release" | head -n1)"

  if [[ -z "$url" || "$url" == "null" ]]; then
    echo "WARNING: no asset for ${system} (${suffix}) in ${tag}, skipping" >&2
    continue
  fi

  echo "Prefetching ${system}: ${url}" >&2
  hash="$(nix store prefetch-file --json --unpack "$url" | jq -r '.hash')"

  assets_json="$(jq \
    --arg sys "$system" --arg url "$url" --arg hash "$hash" \
    '.[$sys] = {url: $url, hash: $hash}' <<<"$assets_json")"
done

jq -n \
  --arg version "$version" \
  --arg tag "$tag" \
  --argjson assets "$assets_json" \
  '{version: $version, tag: $tag, assets: $assets}' \
  >"${DIR}/sources.json"

echo "Wrote ${DIR}/sources.json (version ${version})" >&2
