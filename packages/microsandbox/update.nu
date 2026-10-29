#!/usr/bin/env -S nu --no-config-file
# nix-update cannot do this one: the libkrunfw fork is a submodule pinned per
# tag, and its kernel tarball is named only inside the fork's Makefile.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "superradcompany/microsandbox"
const FW_REPO = "superradcompany/libkrunfw"

const VERSION = {attr: "version"}
const SRC_HASH = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}]}
const CARGO = {attr: "cargoHash"}

const FW_REV = {attr: "rev", under: [{bind: "src", call: "fetchFromGitHub"}]}
const FW_HASH = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}]}
const KERNEL_VERSION = {attr: "kernelVersion"}
const KERNEL_HASH = {attr: "hash", under: [{bind: "kernelSrc", call: "fetchurl"}]}

def make-var [makefile: string, name: string]: nothing -> string {
  let hits = ($makefile | parse -r ('(?m)^' + $name + ' = (?<v>\S+)$') | get v)
  if ($hits | length) != 1 { die $"expected one ($name) in the libkrunfw Makefile, found ($hits | length)" }
  $hits.0
}

def main [] {
  let file = (pkg-file)
  let fw_file = (pkg-dir | path join "libkrunfw.nix")
  let current = (open --raw $file | nix-read $VERSION)
  let release = (gh-latest-release $REPO)

  if $release.version == $current {
    info "already up to date"
    return
  }

  let tag = $release.tag
  let src_hash = (nurl-hash $"https://github.com/($REPO)" $tag)
  info $"src hash: ($src_hash)"

  let cargo_hash = (recover-hash $'
    let src = pkgs.fetchFromGitHub {owner = "superradcompany"; repo = "microsandbox"; tag = "($tag)"; hash = "($src_hash)";};
    in pkgs.rustPlatform.fetchCargoVendor {inherit src; hash = "";}')
  info $"cargo hash: ($cargo_hash)"

  let submodule = (http get $"https://api.github.com/repos/($REPO)/contents/vendor/libkrunfw?ref=($tag)")
  if $submodule.type != "submodule" { die $"vendor/libkrunfw at ($tag) is a ($submodule.type), not a submodule" }
  let fw_rev = $submodule.sha

  let utils = (fetch-text $"https://raw.githubusercontent.com/($REPO)/($tag)/crates/utils/lib/lib.rs")
  let expected_fw = ($utils | parse -r 'pub const LIBKRUNFW_VERSION: &str = "(?<v>[^"]+)";' | get -o v.0)
  if ($expected_fw | is-empty) { die "LIBKRUNFW_VERSION not found in crates/utils/lib/lib.rs" }

  let fw_src = (open --raw $fw_file)
  let fw_updated = if $fw_rev == ($fw_src | nix-read $FW_REV) {
    info $"libkrunfw unchanged at ($fw_rev)"
    if $expected_fw != ($fw_src | nix-read $VERSION) {
      die $"LIBKRUNFW_VERSION is ($expected_fw) but the unchanged submodule builds ($fw_src | nix-read $VERSION)"
    }
    null
  } else {
    let makefile = (fetch-text $"https://raw.githubusercontent.com/($FW_REPO)/($fw_rev)/Makefile")
    let fw_version = (make-var $makefile "FULL_VERSION")
    if $fw_version != $expected_fw {
      die $"libkrunfw ($fw_rev) builds ($fw_version), but msb ($release.version) expects ($expected_fw)"
    }
    let kernel = (make-var $makefile "KERNEL_VERSION" | str replace -r '^linux-' '')
    let major = ($kernel | split row "." | first)
    let fw_hash = (nurl-hash $"https://github.com/($FW_REPO)" $fw_rev)
    let kernel_hash = (prefetch-url $"https://cdn.kernel.org/pub/linux/kernel/v($major).x/linux-($kernel).tar.xz")
    info $"libkrunfw ($fw_version) at ($fw_rev), kernel ($kernel)"
    (
      $fw_src
      | nix-set $VERSION $fw_version
      | nix-set $FW_REV $fw_rev
      | nix-set $FW_HASH $fw_hash
      | nix-set $KERNEL_VERSION $kernel
      | nix-set $KERNEL_HASH $kernel_hash
    )
  }

  let updated = (
    open --raw $file
    | nix-set $VERSION $release.version
    | nix-set $SRC_HASH $src_hash
    | nix-set $CARGO $cargo_hash
  )

  if (dry-run) {
    info "dry run, not writing"
    print -n $updated
    if $fw_updated != null { print -n $fw_updated }
    return
  }

  $updated | save -f $file
  if $fw_updated != null { $fw_updated | save -f $fw_file }
  info $"($current) -> ($release.version)"
}
