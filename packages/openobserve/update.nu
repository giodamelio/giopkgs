#!/usr/bin/env -S nu --no-config-file
# nix-update cannot drive this package: the web UI's npmDepsHash sits in a
# let-bound buildNpmPackage that the flake never exposes as an attribute, and
# the enterprise edition is a second source with a hash of its own.
#
# Idempotent: run against an already-current package it produces no changes.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "openobserve/openobserve"

const VERSION = {attr: "version"}
const SRC = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}]}
const EE_SRC = {attr: "hash", under: [{bind: "src", call: "fetchurl"}]}
const NPM = {attr: "npmDepsHash"}
const CARGO = {attr: "cargoHash"}

def ee-url [version: string]: nothing -> string {
  $"https://downloads.openobserve.ai/releases/o2-enterprise/v($version)/openobserve-ee-v($version)-linux-amd64-musl.tar.gz"
}

def main [] {
  let file = (pkg-file)

  # Release candidates are tagged alongside stable releases, and sort ahead of
  # them — v1.0.0-rc1 is the first tag while v0.92.2 is the newest release.
  let tag = (gh-tags $REPO --match '^v\d+\.\d+\.\d+$' | first)
  let version = ($tag | str replace -r '^v' '')
  info $"latest tag: ($tag)"

  info "computing hashes"
  let src_hash = (nurl-hash $"https://github.com/($REPO)" $tag)
  let ee_hash = (prefetch-url (ee-url $version))

  let lock = (mktemp -d | path join "package-lock.json")
  (fetch-text $"https://raw.githubusercontent.com/($REPO)/($tag)/web/package-lock.json"
    | save -f $lock)
  let npm_hash = (prefetch-npm $lock)

  let cargo_hash = (recover-hash $'
  let src = pkgs.fetchFromGitHub {owner = "openobserve"; repo = "openobserve"; tag = "($tag)"; hash = "($src_hash)";};
  in pkgs.rustPlatform.fetchCargoVendor {inherit src; hash = "";}')

  let updated = (
    open --raw $file
    | nix-set $VERSION $version
    | nix-set $SRC $src_hash
    | nix-set $EE_SRC $ee_hash
    | nix-set $NPM $npm_hash
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
  info $"updated to ($version)"
}
