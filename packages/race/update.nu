#!/usr/bin/env -S nu --no-config-file
# RACE is closed source with no repository or release API; the changelog page is
# the only list of versions, through its per-release download links.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const CHANGELOG = "https://race-term.com/changelog/"
const RELEASES = "https://downloads.race-term.com/releases"
const VERSION = {attr: "version"}
const HASH = {attr: "hash", under: [{bind: "src", call: "fetchurl"}]}

def latest-version []: nothing -> string {
  let versions = (
    fetch-text $CHANGELOG
    | parse -r '/releases/v(?<v>\d+\.\d+\.\d+)/'
    | get v
    | uniq
  )
  if ($versions | is-empty) { die $"no release links on ($CHANGELOG)" }
  $versions
  | sort-by {|v| $v | split row "." | each { into int } }
  | last
}

def main [] {
  let file = (pkg-file)
  let current = (open --raw $file | nix-read $VERSION)
  let version = (latest-version)

  if $version == $current {
    info "already up to date"
    return
  }

  let url = $"($RELEASES)/v($version)/RACE-Linux-x86_64.tar.gz"
  info $"v($version): ($url)"
  let hash = (prefetch-url $url)

  let published = (fetch-text $"($url).sha256" | split row " " | first | str trim)
  let fetched = (^nix hash convert --hash-algo sha256 --to base16 $hash | str trim)
  if $published != $fetched {
    die $"($url) hashes to ($fetched), but upstream publishes ($published)"
  }
  info $"hash: ($hash)"

  let updated = (
    open --raw $file
    | nix-set $VERSION $version
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
