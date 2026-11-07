#!/usr/bin/env -S nu --no-config-file
# Tracks the -cluster tags, which nix-update cannot find: the version literal
# lives in this override, while unsafeGetAttrPos points into nixpkgs. Releases
# are not used because LTS patch releases interleave with mainline ones; the
# highest semver among the -cluster tags is the newest mainline build.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "VictoriaMetrics/VictoriaMetrics"

const VERSION = {attr: "version"}
const SRC = {attr: "hash", under: [{bind: "src", call: "pkgs.fetchFromGitHub"}]}

def main [] {
  let file = (pkg-file)

  let latest = (
    http get $"https://api.github.com/repos/($REPO)/git/matching-refs/tags/v1."
    | get ref
    | parse -r '^refs/tags/v(?<v>\d+\.\d+\.\d+)-cluster$'
    | get v
    | sort-by {|v| $v | split row '.' | each {into int}}
    | last
  )
  let version = $"($latest)-cluster"
  info $"latest cluster tag: v($version)"

  if (open --raw $file | nix-read $VERSION) == $version {
    info "already up to date"
    return
  }

  let hash = (nurl-hash $"https://github.com/($REPO)" $"v($version)")

  let updated = (
    open --raw $file
    | nix-set $VERSION $version
    | nix-set $SRC $hash
  )

  if (dry-run) {
    info "dry run, not writing"
    print -n $updated
    return
  }

  $updated | save -f $file
  nix-build (attr)
  info $"updated to ($version)"
}
