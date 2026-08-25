#!/usr/bin/env -S nu --no-config-file
# SurrealDB Studio is a proprietary download with no git repo and no release
# index for nix-update to read: latest.txt is the only version marker, and each
# architecture ships its own AppImage under a version-stamped path.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const CHANNEL = "https://download.surrealdb.com/studio"

const VERSION = {attr: "version"}

const IMAGES = [
  {suffix: "", site: {attr: "x86_64Hash"}}
  {suffix: "-arm64", site: {attr: "aarch64Hash"}}
]

def main [] {
  let file = (pkg-file)

  let version = (fetch-text $"($CHANNEL)/latest.txt" | str trim | str replace -r '^v' '')
  if ($version | is-empty) { die "the release channel named no version" }

  let current = (open --raw $file | nix-read $VERSION)
  info $"current ($current), upstream ($version)"
  if $version == $current {
    info "already up to date"
    return
  }

  let hashes = (
    $IMAGES | each {|img|
      # The published filename really does contain a space, which nix refuses as
      # a store name, so name the fetch exactly as package.nix does.
      let url = $"($CHANNEL)/v($version)/SurrealDB%20Studio-($version)($img.suffix).AppImage"
      let name = $"surrealdb-studio-($version)($img.suffix).AppImage"
      info $"prefetching ($name)"
      {site: $img.site, hash: (prefetch-url $url --name $name)}
    }
  )

  if (dry-run) {
    info "dry run, not writing package.nix"
    print ({version: $version, hashes: ($hashes | select site.attr hash)} | to json)
    return
  }

  let updated = (
    $hashes | reduce --fold (open --raw $file | nix-set $VERSION $version) {|it, acc|
      $acc | nix-set $it.site $it.hash
    }
  )

  # The write lands before the verification build, so this one needs rollback.
  with-rollback [$file] {
    $updated | save -f $file
    nix-build (attr)
  }

  info $"updated to ($version)"
}
