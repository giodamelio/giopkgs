#!/usr/bin/env -S nu --no-config-file
# nix-update can't drive this package: the prebuilt prism UI bundle is a third
# hash whose URL embeds the release version, so bumping the version alone leaves
# it stale and the build fails.
#
# Upstream's build.rs downloads that same zip and checks it against the
# assets-url/assets-sha1 pinned in its Cargo.toml, and LOCAL_ASSETS_PATH is
# upstream's own escape hatch for supplying it out of band. So Cargo.toml is
# treated as the source of truth, and this refuses to update if upstream ever
# stops tracking the release version with the UI version.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "parseablehq/parseable"
const BUNDLE = "https://parseable-prism-build.s3.us-east-2.amazonaws.com"

const VERSION = {attr: "version"}
const SRC = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}]}
const UI = {attr: "hash", under: [{bind: "LOCAL_ASSETS_PATH", call: "fetchzip"}]}
const CARGO = {attr: "hash", under: [{bind: "cargoDeps", call: "rustPlatform.fetchCargoVendor"}]}

def main [] {
  let file = (pkg-file)
  let current = (open --raw $file | nix-read $VERSION)
  let rel = (gh-latest-release $REPO)

  info $"current ($current), latest ($rel.version)"
  if $current == $rel.version {
    info "already up to date"
    return
  }

  let manifest = (fetch-text $"https://raw.githubusercontent.com/($REPO)/($rel.tag)/Cargo.toml")
  let ui_url = ($manifest | parse -r 'assets-url = "(?<v>[^"]+)"' | get v.0)
  let ui_sha1 = ($manifest | parse -r 'assets-sha1 = "(?<v>[^"]+)"' | get v.0)

  let expected = $"($BUNDLE)/v($rel.version)/build.zip"
  if $ui_url != $expected {
    die $"the prism URL no longer tracks the release version:
  Cargo.toml: ($ui_url)
  expected:   ($expected)
package.nix interpolates the version into that URL, so this needs a manual fix."
  }

  info "verifying the prism bundle against upstream's pinned sha1"
  let got_sha1 = (sha1-of (prefetch-store-path $ui_url))
  if $got_sha1 != $ui_sha1 {
    die $"prism bundle sha1 mismatch: upstream pins ($ui_sha1), got ($got_sha1)"
  }

  let src_hash = (nurl-hash $"https://github.com/($REPO)" $rel.tag)
  let ui_hash = (prefetch-url $ui_url --unpack --name source)

  # Build the vendor derivation from the source we just resolved, rather than
  # blanking the hash in package.nix and reading the error. Nothing has touched
  # disk at this point, so there is no half-written state to recover from.
  let cargo_hash = (recover-hash $'
    let src = pkgs.fetchFromGitHub {
      owner = "parseablehq";
      repo = "parseable";
      tag = "($rel.tag)";
      hash = "($src_hash)";
    };
    in pkgs.rustPlatform.fetchCargoVendor {inherit src; hash = "";}')

  let updated = (
    open --raw $file
    | nix-set $VERSION $rel.version
    | nix-set $SRC $src_hash
    | nix-set $UI $ui_hash
    | nix-set $CARGO $cargo_hash
  )

  if (dry-run) {
    info "dry run, not writing"
    print -n $updated
    return
  }

  with-rollback $file {
    $updated | save -f $file
    nix-build (attr)
  }
  info $"($current) -> ($rel.version)"
}
