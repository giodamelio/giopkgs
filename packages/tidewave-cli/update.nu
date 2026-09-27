#!/usr/bin/env -S nu --no-config-file
# nix-update cannot do this one: src is wrapped in applyPatches, so it has to
# skip the source, and its cargoHash is then computed against the stale src
# hash — which resolves to the old tree and leaves cargoHash unchanged.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "tidewave-ai/tidewave_app"

# `stopBy: end` walks through the outer `src = applyPatches`, so these match the
# inner fetchFromGitHub and not the wrapper.
const IN_SRC = {bind: "src", call: "fetchFromGitHub"}
const REV = {attr: "rev", under: [$IN_SRC]}
const HASH = {attr: "hash", under: [$IN_SRC]}
const VERSION = {attr: "version"}
const CARGO = {attr: "cargoHash"}

def main [] {
  let file = (pkg-file)
  let current = (open --raw $file | nix-read $VERSION)
  let release = (gh-latest-release $REPO)

  if $release.version == $current {
    info "already up to date"
    return
  }

  let src_hash = (nurl-hash $"https://github.com/($REPO)" $release.tag)
  info $"src hash: ($src_hash)"

  # The patches rewrite Cargo.lock, so the vendor hash is taken over the
  # patched tree, reusing p.src's patches with only the inner fetch swapped.
  let cargo_hash = (recover-hash $'
    let src = p.src.overrideAttrs {
      src = pkgs.fetchFromGitHub {
        owner = "tidewave-ai";
        repo = "tidewave_app";
        rev = "($release.tag)";
        hash = "($src_hash)";
      };
    };
    in pkgs.rustPlatform.fetchCargoVendor {inherit src; hash = "";}')
  info $"cargo hash: ($cargo_hash)"

  let updated = (
    open --raw $file
    | nix-set $VERSION $release.version
    | nix-set $REV $release.tag
    | nix-set $HASH $src_hash
    | nix-set $CARGO $cargo_hash
  )

  if (dry-run) {
    info "dry run, not writing"
    print -n $updated
    return
  }

  with-rollback [$file] {
    $updated | save -f $file
    nix-build (attr)
  }
  info $"($current) -> ($release.version)"
}
