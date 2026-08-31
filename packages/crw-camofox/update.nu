#!/usr/bin/env -S nu --no-config-file
# Same --override-filename fix as packages/crw/update.nu (the shared builder in
# common.nix owns the `version` attribute position), plus --version=branch: the
# camofox work lives on the fork's default branch and the v1.x tags sit behind
# it, so there is no release to track.

use ../../scripts/update.nu *

def main [] {
  let file = (pkg-file)
  ^nix-update --flake --version=branch --override-filename $file (attr)
}
