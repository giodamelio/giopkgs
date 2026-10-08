#!/usr/bin/env -S nu --no-config-file
# There is no src for nix-update to follow: the whole package is uv.lock.

use ../../scripts/update.nu *

def main [] {
  let dir = (pkg-dir)

  if (dry-run) {
    ^uv lock --upgrade --dry-run --directory $dir
    return
  }

  with-rollback [($dir | path join "uv.lock")] {
    ^uv lock --upgrade --directory $dir
    nix-build (attr)
  }
}
