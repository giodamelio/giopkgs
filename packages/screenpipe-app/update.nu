#!/usr/bin/env -S nu --no-config-file
# nix-update can't drive this package:
#
#   * the vendored Cargo.lock is upstream's with the macOS-only nokhwa git
#     dependency pruned, because fetchCargoVendor cannot find that crate's
#     manifest in its repository — nix-update would copy upstream's lock verbatim;
#   * the bun frontend is a fixed-output derivation nix-update does not know of.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "screenpipe/screenpipe"
const CARGO_ROOT = "apps/screenpipe-app-tauri/src-tauri"
const PRUNED_DEP = "nokhwa-bindings-macos"

const VERSION = {attr: "version"}
const SRC = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}]}
const FRONTEND = {attr: "outputHash", under: [{bind: "frontend", call: "stdenv.mkDerivation"}]}
const CARGO = {attr: "hash", under: [{bind: "cargoDeps", call: "rustPlatform.fetchCargoVendor"}]}

def parse-block [text: string]: nothing -> record {
  let field = {|key| $text | parse -r ('(?m)^' + $key + ' = "(?<v>[^"]+)"$') | get -o v.0}
  {
    text: $text
    name: (do $field "name")
    version: (do $field "version")
    source: (do $field "source")
    deps: ($text | parse -r '(?m)^ "(?<d>[^"]+)",$' | each {|r| $r.d})
  }
}

def resolve [by_name: record, spec: string]: nothing -> int {
  let m = ($spec | parse -r '^(?<name>\S+)(?: (?<version>\S+))?(?: \((?<source>.+)\))?$' | first)
  let hits = ($by_name | get -o $m.name | default [] | where {|b|
    (($m.version | is-empty) or $b.item.version == $m.version) and (($m.source | is-empty) or ($b.item.source | str replace -r '#.*$' '') == $m.source)
  })
  if ($hits | length) != 1 { die $"Cargo.lock dependency '($spec)' matches ($hits | length) packages" }
  $hits.0.index
}

# Drops the dependency, then every package no longer reachable from the local
# crates: nokhwa-core lives in the same repository and breaks vendoring the same
# way. Whole [[package]] blocks are removed as text, so the rest of the lock
# stays byte-for-byte upstream's.
def prune-lock [lock: string]: nothing -> string {
  let sep = "\n\n[[package]]\n"
  let chunks = ($lock | str trim --right --char "\n" | split row $sep)
  let dep_line = $"\n \"($PRUNED_DEP)\","

  let refs = ($lock | split row $dep_line | length) - 1
  if $refs != 1 {
    die $"expected one reference to ($PRUNED_DEP) in Cargo.lock, found ($refs) — check the Cargo.toml sed in package.nix"
  }

  let blocks = ($chunks | skip 1 | each {|c| parse-block ($c | str replace $dep_line "")})
  if ($blocks | any {|b| $b.text =~ '(?m)^dependencies = \[\n\]'}) {
    die $"pruning ($PRUNED_DEP) left an empty dependencies list, which cargo would omit"
  }

  let by_name = ($blocks | enumerate | group-by {|b| $b.item.name})
  mut keep = ($blocks | enumerate | where {|b| $b.item.source == null} | get index)
  mut frontier = $keep
  while ($frontier | is-not-empty) {
    let seen = $keep
    let next = ($frontier
      | each {|i| $blocks | get $i | get deps | each {|d| resolve $by_name $d}}
      | flatten | uniq | where {|i| $i not-in $seen})
    $keep = ($keep | append $next)
    $frontier = $next
  }

  let kept = ($blocks | enumerate | where {|b| $b.index in $keep} | get item.text)
  info $"pruned ($blocks | length | $in - ($kept | length)) packages from Cargo.lock"
  ([$chunks.0 ...$kept] | str join $sep) + "\n"
}

def main [] {
  let file = (pkg-file)
  let lock_dest = (pkg-dir | path join "Cargo.lock")
  let current = (open --raw $file | nix-read $VERSION)
  let tag = (gh-latest-release $REPO).tag

  info $"current ($current), latest ($tag)"
  if $current == $tag {
    info "already up to date"
    return
  }

  let work = (mktemp -d)
  let lock = ($work | path join "Cargo.lock")
  fetch-text $"https://raw.githubusercontent.com/($REPO)/($tag)/($CARGO_ROOT)/Cargo.lock"
  | prune-lock $in
  | save -f $lock

  let src_hash = (nurl-hash $"https://github.com/($REPO)" $tag)
  let src_expr = $'pkgs.fetchFromGitHub {owner = "screenpipe"; repo = "screenpipe"; tag = "($tag)"; hash = "($src_hash)";}'

  info "recovering the frontend hash"
  let frontend_hash = (recover-hash $'
    p.frontend.overrideAttrs {version = "($tag)"; src = ($src_expr); outputHash = "";}')

  info "recovering the cargo vendor hash"
  let cargo_hash = (recover-hash $'
    pkgs.rustPlatform.fetchCargoVendor {
      src = pkgs.lib.fileset.toSource {root = ($work); fileset = ($lock);};
      hash = "";
    }')

  let updated = (
    open --raw $file
    | nix-set $VERSION $tag
    | nix-set $SRC $src_hash
    | nix-set $FRONTEND $frontend_hash
    | nix-set $CARGO $cargo_hash
  )

  if (dry-run) {
    info "dry run, not writing"
    print -n $updated
    return
  }

  with-rollback [$file $lock_dest] {
    cp $lock $lock_dest
    $updated | save -f $file
    nix-build (attr)
  }
  info $"($current) -> ($tag)"
}
