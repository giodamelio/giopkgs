#!/usr/bin/env -S nu --no-config-file
# nix-update cannot drive this package: one release feeds three files.
#
#   * package.nix pins the git tag both halves share;
#   * desktop.nix pins the two prebuilt .debs that tag released;
#   * cli.nix pins an npm lockfile that has to be regenerated from the tag,
#     because apps/cli ships none — it is a bun workspace member.
#
# Idempotent: run against an already-current package it produces no changes.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "pounce-ai/pounce"

# Only `v*` releases carry the Linux desktop app. `desktop-v*` is the separate
# macOS-native app and `bridge-latest` is a rolling auto-update channel.
const RELEASE_TAG = '^v\d'

# scripts/build.mjs keeps only the packages in its EXTERNAL list external, so
# these get inlined into dist/ and must resolve while bun bundles — but the
# published CLI package declares neither. Versions come from apps/bridge, which
# does declare them, so they cannot drift from what the bridge was tested with.
const INLINED_DEPS = ["agent-canonical" "node-machine-id"]

const VERSION = {attr: "version"}
const SRC = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}]}
const AMD64 = {attr: "amd64Hash"}
const ARM64 = {attr: "arm64Hash"}
const NPM = {attr: "hash", under: [{bind: "npmDeps", call: "fetchNpmDeps"}]}

def latest-tag []: nothing -> string {
  let releases = (
    http get $"https://api.github.com/repos/($REPO)/releases?per_page=50"
    | where {|r| (not $r.draft) and (not $r.prerelease) and ($r.tag_name =~ $RELEASE_TAG)}
  )
  if ($releases | is-empty) { die $"no ($RELEASE_TAG) release found for ($REPO)" }
  $releases | first | get tag_name
}

def manifest-at [tag: string, app: string]: nothing -> record {
  http get $"https://raw.githubusercontent.com/($REPO)/($tag)/apps/($app)/package.json"
}

def deb-url [version: string, arch: string]: nothing -> string {
  $"https://github.com/($REPO)/releases/download/v($version)/pounce_($version)_($arch).deb"
}

# The CLI manifest as npm should see it: no devDependencies to install, plus the
# two dependencies bun inlines. Written out alongside the lockfile it generates,
# because `npm ci` rejects a lockfile that disagrees with its package.json.
def cli-manifest [tag: string]: nothing -> record {
  let cli = (manifest-at $tag "cli")
  let bridge = (manifest-at $tag "bridge")
  let inlined = ($bridge.dependencies | select ...$INLINED_DEPS)

  $cli
  | reject -o devDependencies
  | update dependencies ($cli.dependencies | merge $inlined | sort)
}

def regenerate-lockfile [tag: string]: nothing -> path {
  let work = (mktemp -d)
  cli-manifest $tag | to json --indent 2 | save -f ($work | path join "package.json")

  cd $work
  let out = (^npm install --package-lock-only --ignore-scripts | complete)
  if $out.exit_code != 0 {
    die $"npm install failed:\n($out.stderr | lines | last 20 | str join (char nl))"
  }
  $work
}

def main [] {
  let pkg_file = (pkg-file)
  let desktop_file = (pkg-dir | path join "desktop.nix")
  let cli_file = (pkg-dir | path join "cli.nix")
  let manifest_dest = (pkg-dir | path join "cli-npm" "package.json")
  let lock_dest = (pkg-dir | path join "cli-npm" "package-lock.json")

  let tag = (latest-tag)
  let version = ($tag | str replace -r '^v' '')
  info $"latest release: ($tag)"

  info "regenerating the npm lockfile"
  let npm_dir = (regenerate-lockfile $tag)

  info "computing hashes"
  let src_hash = (nurl-hash $"https://github.com/($REPO)" $tag)
  let amd64_hash = (prefetch-url (deb-url $version "amd64"))
  let arm64_hash = (prefetch-url (deb-url $version "arm64"))
  let npm_hash = (prefetch-npm ($npm_dir | path join "package-lock.json"))

  let pkg = (open --raw $pkg_file | nix-set $VERSION $version | nix-set $SRC $src_hash)
  let desktop = (open --raw $desktop_file | nix-set $AMD64 $amd64_hash | nix-set $ARM64 $arm64_hash)
  let cli = (open --raw $cli_file | nix-set $NPM $npm_hash)

  if (dry-run) {
    info "dry run, not writing"
    print $"($version) ($src_hash) ($amd64_hash) ($arm64_hash) ($npm_hash)"
    return
  }

  # The vendored manifest and lockfile are inputs to npm_hash, so they land with
  # the .nix files or the package is left inconsistent.
  with-rollback [$pkg_file $desktop_file $cli_file $manifest_dest $lock_dest] {
    $pkg | save -f $pkg_file
    $desktop | save -f $desktop_file
    $cli | save -f $cli_file
    cp ($npm_dir | path join "package.json") $manifest_dest
    cp ($npm_dir | path join "package-lock.json") $lock_dest
    nix-build (attr)
  }
  info $"updated to ($version)"
}
