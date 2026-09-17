#!/usr/bin/env -S nu --no-config-file
# Regenerate sources.json from the latest GitHub release.
#
# nix-update can't drive this package: each Nix system needs its own asset URL
# and hash. The hashes come from the release's own binaries.json, so an update
# never has to download the ~95 MB archives — a wrong hash there just fails the
# build loudly.

use ../../scripts/update.nu *

const REPO = "beeper/cli"

# binaries.json platform -> Nix system double.
const SYSTEMS = {
  "linux-x64": "x86_64-linux"
  "linux-arm64": "aarch64-linux"
}

def sri-of [hex: string]: nothing -> string {
  ^nix hash convert --hash-algo sha256 --to sri $hex | str trim
}

def main [] {
  let rel = (gh-latest-release $REPO)
  info $"latest release: ($rel.tag)"

  let meta_asset = ($rel.assets | where name == "binaries.json")
  if ($meta_asset | is-empty) { die $"($rel.tag) ships no binaries.json" }
  # Served as application/octet-stream, so nushell hands back bytes, not JSON.
  let binaries = (
    http get --raw ($meta_asset | first | get browser_download_url)
    | decode utf-8
    | from json
  )

  if $binaries.version != $rel.version {
    die $"binaries.json says ($binaries.version), tag says ($rel.version)"
  }

  let assets = (
    $SYSTEMS
    | transpose platform system
    | each {|entry|
      let artifacts = ($binaries.artifacts | where platform == $entry.platform)
      if ($artifacts | is-empty) {
        die $"($rel.tag) has no ($entry.platform) artifact"
      }
      let artifact = ($artifacts | first)

      let release_assets = ($rel.assets | where name == $artifact.file)
      if ($release_assets | is-empty) {
        die $"binaries.json names ($artifact.file), which ($rel.tag) does not ship"
      }

      {
        system: $entry.system
        value: {
          url: ($release_assets | first | get browser_download_url)
          hash: (sri-of $artifact.sha256)
        }
      }
    }
    | reduce --fold {} {|it, acc| $acc | insert $it.system $it.value}
  )

  let sources = {version: $rel.version, tag: $rel.tag, assets: $assets}

  if (dry-run) {
    info "dry run, not writing sources.json"
    print ($sources | to json)
    return
  }

  $"($sources | to json)(char nl)" | save -f (pkg-dir | path join "sources.json")
  info $"wrote sources.json \(version ($rel.version))"
}
