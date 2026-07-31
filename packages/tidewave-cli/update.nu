#!/usr/bin/env -S nu --no-config-file
# src is wrapped in applyPatches, which produces a directory and so cannot be
# flat-hashed. nix-update has to skip the source entirely, leaving us to
# prefetch and write the fetchFromGitHub hash ourselves.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

# `stopBy: end` walks through the outer `src = applyPatches`, so these match the
# inner fetchFromGitHub and not the wrapper.
const IN_SRC = {bind: "src", call: "fetchFromGitHub"}
const OWNER = {attr: "owner", under: [$IN_SRC]}
const REPO = {attr: "repo", under: [$IN_SRC]}
const REV = {attr: "rev", under: [$IN_SRC]}
const HASH = {attr: "hash", under: [$IN_SRC]}

def main [] {
  let file = (pkg-file)
  let before = (open --raw $file)

  with-rollback [$file] {
    run-nix-update "--no-src" "--lockfile-metadata-path" (attr)

    if (open --raw $file) == $before {
      info "no change"
    } else {
      let src = (open --raw $file)
      let owner = ($src | nix-read $OWNER)
      let repo = ($src | nix-read $REPO)
      let rev = ($src | nix-read $REV)

      let hash = (prefetch-url $"https://github.com/($owner)/($repo)/archive/($rev).tar.gz" --unpack)
      info $"src hash: ($hash)"

      $src | nix-set $HASH $hash | save -f $file
      nix-build (attr)
    }
  }
}
