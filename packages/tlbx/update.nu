#!/usr/bin/env -S nu --no-config-file
# Regenerate sources.json from the newest tlbx release.
#
# Two reasons nix-update can't drive this: the release ships prebuilt Native AOT
# tarballs, so each system needs its own URL and hash, and upstream's current
# channel is the `-dev` prerelease line, which /releases/latest never returns.

use ../../scripts/update.nu *

const REPO = "tlbx-ai/tlbx"

# tlbx asset arch suffix -> Nix system double.
const SYSTEMS = {
  "linux-x64": "x86_64-linux"
  "linux-arm64": "aarch64-linux"
}

def main [] {
  # /releases is ordered newest-first and, unlike /releases/latest, includes
  # prereleases — which is the whole dev channel.
  let rel = (http get $"https://api.github.com/repos/($REPO)/releases" | first)
  info $"newest release: ($rel.tag_name)"

  let assets = (
    $SYSTEMS
    | transpose suffix system
    | each {|entry|
      let name = $"mt-($entry.suffix).tar.gz"
      let matches = ($rel.assets | where name == $name)
      if ($matches | is-empty) {
        die $"($rel.tag_name) has no ($name) — refusing to publish a partial release"
      }
      let url = ($matches | first | get browser_download_url)
      info $"prefetching ($entry.system)"
      {system: $entry.system, value: {url: $url, hash: (prefetch-url $url --unpack)}}
    }
    | reduce --fold {} {|it, acc| $acc | insert $it.system $it.value}
  )

  let sources = {
    version: ($rel.tag_name | str replace -r '^v' '')
    tag: $rel.tag_name
    assets: $assets
  }

  if (dry-run) {
    info "dry run, not writing sources.json"
    print ($sources | to json)
    return
  }

  $"($sources | to json)(char nl)" | save -f (pkg-dir | path join "sources.json")
  info $"wrote sources.json \(version ($sources.version))"
}
