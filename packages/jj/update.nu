#!/usr/bin/env -S nu --no-config-file
# nix-update --version=branch would bump the rev and the source hash, but this
# package replaces jujutsu's cargoDeps outright, and that hash lives in a
# fetchCargoVendor nix-update does not know about.
#
# The verification build is the point of the rollback: it is what catches the
# out-of-tree patch no longer applying to main.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "jj-vcs/jj"
const BRANCH = "main"

const VERSION = {attr: "version"}
const REV = {attr: "rev"}
const SRC = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}]}
const CARGO = {attr: "hash", under: [{bind: "cargoDeps", call: "rustPlatform.fetchCargoVendor"}]}

def main [] {
  let file = (pkg-file)
  let current = (open --raw $file | nix-read $REV)

  let head = (http get $"https://api.github.com/repos/($REPO)/commits/($BRANCH)")
  let rev = $head.sha
  let date = ($head.commit.committer.date | into datetime | format date "%Y-%m-%d")

  info $"current ($current), ($BRANCH) at ($rev)"
  if $current == $rev {
    info "already up to date"
    return
  }

  let manifest = (fetch-text $"https://raw.githubusercontent.com/($REPO)/($rev)/Cargo.toml")
  let crate_version = ($manifest | parse -r '(?m)^version = "(?<v>[^"]+)"' | get v.0)
  let version = $"($crate_version)-unstable-($date)"

  let src_hash = (nurl-hash $"https://github.com/($REPO)" $rev)
  let cargo_hash = (recover-hash $'
    let src = pkgs.fetchFromGitHub {
      owner = "jj-vcs";
      repo = "jj";
      rev = "($rev)";
      hash = "($src_hash)";
    };
    in pkgs.rustPlatform.fetchCargoVendor {inherit src; hash = "";}')

  let updated = (
    open --raw $file
    | nix-set $VERSION $version
    | nix-set $REV $rev
    | nix-set $SRC $src_hash
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
  info $"($current) -> ($rev) \(($version))"
}
