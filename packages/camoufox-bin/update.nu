#!/usr/bin/env -S nu --no-config-file
# Regenerate sources.json from the latest GitHub release.
#
# nix-update can't drive this package: within a single tag the release assets
# carry inconsistent per-platform version strings (lin.x86_64 might say
# "alpha.26" while lin.arm64 says "alpha.25" inside the same "beta.25" tag), so
# every system needs its own URL and hash.

use ../../scripts/update.nu *

const REPO = "daijro/camoufox"

# Camoufox asset arch suffix -> Nix system double.
const SYSTEMS = {
  "lin.x86_64": "x86_64-linux"
  "lin.arm64": "aarch64-linux"
}

def main [] {
  let rel = (gh-latest-release $REPO)
  info $"latest release: ($rel.tag)"

  let found = (
    $SYSTEMS
    | transpose suffix system
    | each {|entry|
      let matches = ($rel.assets | where {|a| $a.name | str ends-with $"-($entry.suffix).zip"})
      if ($matches | is-empty) {
        # A missing platform is not fatal: publish what upstream actually shipped.
        info $"no asset for ($entry.system) \(($entry.suffix)) in ($rel.tag), skipping"
        null
      } else {
        let asset = ($matches | first)
        info $"prefetching ($entry.system)"
        {
          system: $entry.system
          value: {url: $asset.browser_download_url, hash: (prefetch-url $asset.browser_download_url --unpack)}
        }
      }
    }
    | compact
  )

  if ($found | is-empty) { die $"no usable assets in ($rel.tag)" }

  let sources = {
    version: $rel.version
    tag: $rel.tag
    assets: ($found | reduce --fold {} {|it, acc| $acc | insert $it.system $it.value})
  }

  if (dry-run) {
    info "dry run, not writing sources.json"
    print ($sources | to json)
    return
  }

  $"($sources | to json)(char nl)" | save -f (pkg-dir | path join "sources.json")
  info $"wrote sources.json \(version ($rel.version))"
}
