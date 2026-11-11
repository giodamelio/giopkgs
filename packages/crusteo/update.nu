#!/usr/bin/env -S nu --no-config-file
# nix-update cannot drive this package: source.nix holds the version, src and
# a cargoDeps shared by crusteo, crusteo-reef and crusteo-burrow, and every
# upstream release so far is a pre-release, which releases/latest skips.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "chicagobuss/crusteo"

const VERSION = {attr: "version"}
const SRC = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}]}
const CARGO = {attr: "hash", under: [{bind: "cargoDeps", call: "rustPlatform.fetchCargoVendor"}]}

def latest-tag []: nothing -> string {
  let releases = (
    http get $"https://api.github.com/repos/($REPO)/releases?per_page=20"
    | where {|r| not $r.draft}
  )
  if ($releases | is-empty) { die $"no release found for ($REPO)" }
  $releases | first | get tag_name
}

def main [] {
  let file = (pkg-dir | path join "source.nix")
  let current = (open --raw $file | nix-read $VERSION)
  let tag = (latest-tag)
  let version = ($tag | str replace -r '^v' '')

  if $version == $current {
    info "already up to date"
    return
  }

  let src_hash = (nurl-hash $"https://github.com/($REPO)" $tag)
  info $"src hash: ($src_hash)"

  let cargo_hash = (recover-hash $'
    let src = pkgs.fetchFromGitHub {
      owner = "chicagobuss";
      repo = "crusteo";
      tag = "($tag)";
      hash = "($src_hash)";
    };
    in pkgs.rustPlatform.fetchCargoVendor {inherit src; hash = "";}')
  info $"cargo hash: ($cargo_hash)"

  let updated = (
    open --raw $file
    | nix-set $VERSION $version
    | nix-set $SRC $src_hash
    | nix-set $CARGO $cargo_hash
  )

  if (dry-run) {
    info "dry run, not writing"
    print -n $updated
    return
  }

  $updated | save -f $file
  info $"($current) -> ($version)"
}
