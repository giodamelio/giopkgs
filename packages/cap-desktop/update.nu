#!/usr/bin/env -S nu --no-config-file
# The Linux .deb is not a release asset: it lives on the crabnebula CDN under an
# opaque id that only appears in the release notes' DOWNLOADS_JSON comment, so
# nix-update has no URL pattern to follow.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "CapSoftware/Cap"
const SRC = {bind: "src", call: "fetchurl"}
const VERSION = {attr: "version"}
const URL = {attr: "url", under: [$SRC]}
const HASH = {attr: "hash", under: [$SRC]}

# The repo's releases are not all desktop builds; only `cap-v*` tags are.
def latest-desktop-release []: nothing -> record {
  let releases = (
    http get $"https://api.github.com/repos/($REPO)/releases?per_page=30"
    | where {|r| not $r.draft and not $r.prerelease and ($r.tag_name | str starts-with "cap-v")}
  )
  if ($releases | is-empty) { die "no published cap-v* release" }
  $releases | first
}

def deb-url [body: string]: nothing -> string {
  let found = ($body | parse -r '<!-- DOWNLOADS_JSON (?<json>\{.*?\}) -->')
  if ($found | is-empty) { die "release notes have no DOWNLOADS_JSON block" }
  let downloads = ($found.json.0 | from json)
  if "linux-deb" not-in $downloads { die "DOWNLOADS_JSON has no linux-deb entry" }
  $downloads | get linux-deb
}

def main [] {
  let file = (pkg-file)
  let current = (open --raw $file | nix-read $VERSION)
  let release = (latest-desktop-release)
  let version = ($release.tag_name | str replace -r '^cap-v' '')

  if $version == $current {
    info "already up to date"
    return
  }

  let url = (deb-url $release.body)
  info $"($release.tag_name): ($url)"
  let hash = (prefetch-url $url)
  info $"hash: ($hash)"

  let updated = (
    open --raw $file
    | nix-set $VERSION $version
    | nix-set $URL $url
    | nix-set $HASH $hash
  )

  if (dry-run) {
    info "dry run, not writing"
    print -n $updated
    return
  }

  with-rollback [$file] {
    $updated | save -f $file
    nix-build (attr)
  }
  info $"($current) -> ($version)"
}
