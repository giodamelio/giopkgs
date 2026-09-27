#!/usr/bin/env -S nu --no-config-file
# nix-update cannot drive this package: the AppImage name embeds a build
# timestamp that only the release's asset list knows. Prereleases also name
# their assets differently (ubu24 rather than ubuntu24.04), so only stable
# releases are followed.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "bambulab/BambuStudio"

const VERSION = {attr: "version"}
const TIMESTAMP = {attr: "build_timestamp"}
const SRC = {attr: "sha256", under: [{bind: "src", call: "pkgs.fetchurl"}]}

def main [] {
  let file = (pkg-file)
  let rel = (gh-latest-release $REPO)
  info $"latest release: ($rel.tag)"

  let ubuntu = (open --raw $file | nix-read {attr: "ubuntu_version"})
  let pattern = '^BambuStudio_ubuntu' + ($ubuntu | str replace -a '.' '\.') + '-' + $rel.tag + '-(?<ts>\d+)\.AppImage$'
  let assets = ($rel.assets | where name =~ $pattern)
  if ($assets | length) != 1 {
    die $"expected one asset matching ($pattern) in ($rel.tag), found ($assets | length): ($rel.assets | get name | str join ', ')"
  }
  let asset = ($assets | first)
  let timestamp = ($asset.name | parse -r $pattern | get 0.ts)

  info $"prefetching ($asset.name)"
  let hash = (prefetch-url $asset.browser_download_url)

  let updated = (
    open --raw $file
    | nix-set $VERSION $rel.version
    | nix-set $TIMESTAMP $timestamp
    | nix-set $SRC $hash
  )

  if (dry-run) {
    info "dry run, not writing"
    print -n $updated
    return
  }

  $updated | save -f $file
  nix-build (attr)
  info $"updated to ($rel.version)"
}
