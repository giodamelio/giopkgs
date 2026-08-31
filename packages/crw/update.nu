#!/usr/bin/env -S nu --no-config-file
# nix-update picks the file to rewrite from `unsafeGetAttrPos "version"`, and
# the shared builder in common.nix takes `version` through `inherit`, so that
# position is common.nix — which holds no version literal. Point it back at the
# file that does.

use ../../scripts/update.nu *

def main [] {
  let file = (pkg-file)
  ^nix-update --flake --override-filename $file (attr)
}
