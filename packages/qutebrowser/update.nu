#!/usr/bin/env -S nu --no-config-file
# nix-update --version=branch prefixes the version with the newest tag on the
# fork, and the fork does not carry upstream's release tags — so v3.7.0 source
# was labelled 3.6.3. The prefix is taken from qutebrowser's own __version__
# instead, which is right whatever tags the fork has.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "giodamelio/qutebrowser"

const VERSION = {attr: "version"}
const REV = {attr: "rev"}

def main [] {
  let file = (pkg-file)
  let before = (open --raw $file)

  with-rollback [$file] {
    run-nix-update "--version=branch"

    if (open --raw $file) == $before {
      info "no source change"
      return
    }

    let rev = (open --raw $file | nix-read $REV)
    let init = (fetch-text $"https://raw.githubusercontent.com/($REPO)/($rev)/qutebrowser/__init__.py")
    let upstream = ($init | parse -r '(?m)^__version__ = "(?<v>[^"]+)"' | get v.0)
    let date = (open --raw $file | nix-read $VERSION | parse -r '-unstable-(?<d>\d{4}-\d{2}-\d{2})$' | get d.0)
    let version = $"($upstream)-unstable-($date)"
    info $"version: ($version)"

    open --raw $file | nix-set $VERSION $version | save -f $file
  }
}
