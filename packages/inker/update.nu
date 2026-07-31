#!/usr/bin/env -S nu --no-config-file
# Two things stop nix-update driving this package:
#
#   * upstream's committed package-lock.json files are stale — the real lockfile
#     is bun.lock — so fresh npm lockfiles are regenerated and vendored here;
#   * the pinned Prisma engine binaries are version-locked to a commit hash that
#     is only discoverable from the regenerated backend lockfile.
#
# Idempotent: run against an already-current package it produces no changes.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const REPO = "usetrmnl/inker"
const NPM_DEPS = {bind: "npmDeps", call: "fetchNpmDeps"}

# Dependencies the source imports but never declares. Keep in sync with the
# backend postPatch in package.nix — npm ci rejects a lockfile that disagrees
# with package.json, so a mismatch fails loudly at build time.
const MISSING_DEPS = {
  backend: {
    "bullmq": "^5.34.0"
    "@nestjs/bullmq": "^10.2.3"
  }
}

const VERSION = {attr: "version"}
const SRC = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}]}
const PRISMA_COMMIT = {attr: "prismaEnginesCommit"}
const LIBQUERY = {attr: "hash", under: [{bind: "libquerySrc", call: "fetchurl"}]}
const SCHEMA = {attr: "hash", under: [{bind: "schemaSrc", call: "fetchurl"}]}
const QUERY = {attr: "hash", under: [{bind: "querySrc", call: "fetchurl"}]}
const FRONTEND_NPM = {attr: "hash", under: [$NPM_DEPS], ident: {name: "${pname}-frontend-npm-deps"}}
const BACKEND_NPM = {attr: "hash", under: [$NPM_DEPS], ident: {name: "${pname}-backend-npm-deps"}}

def engine-url [commit: string, engine: string]: nothing -> string {
  $"https://binaries.prisma.sh/all_commits/($commit)/debian-openssl-3.0.x/($engine).gz"
}

def regenerate-lockfile [tag: string, app: string]: nothing -> path {
  let work = (mktemp -d)
  let manifest = ($work | path join "package.json")
  (http get --raw $"https://raw.githubusercontent.com/($REPO)/($tag)/($app)/package.json"
    | save -f $manifest)

  # Since 0.6.0 the backend imports these but declares them nowhere — not in
  # package.json, bun.lock or package-lock.json — so `nest build` cannot resolve
  # them and TypeScript fails with TS2307. Declare them so the lockfile we
  # generate contains them; package.nix patches the same pair into the source's
  # package.json, or `npm ci` would reject the lockfile as out of sync.
  let missing = ($MISSING_DEPS | get -o $app | default {})
  if ($missing | is-not-empty) {
    let pkg = (open $manifest)
    $pkg | update dependencies ($pkg.dependencies | merge $missing) | save -f $manifest
    info $"declared missing ($app) deps: ($missing | columns | str join ', ')"
  }

  cd $work
  let out = (^npm install --package-lock-only --ignore-scripts --legacy-peer-deps | complete)
  if $out.exit_code != 0 {
    die $"npm install failed for ($app):\n($out.stderr | lines | last 20 | str join (char nl))"
  }
  $work | path join "package-lock.json"
}

def main [] {
  let file = (pkg-file)
  let tag = (gh-tags $REPO | first)
  info $"latest tag: ($tag)"

  info "regenerating npm lockfiles"
  let frontend_lock = (regenerate-lockfile $tag "frontend")
  let backend_lock = (regenerate-lockfile $tag "backend")

  # The engine commit is the last dot-segment of @prisma/engines-version.
  let engine_commit = (
    open $backend_lock
    | get packages."node_modules/@prisma/engines-version".version
    | split row "."
    | last
  )
  info $"prisma engine commit: ($engine_commit)"

  info "computing hashes"
  let src_hash = (nurl-hash $"https://github.com/($REPO)" $tag)
  let frontend_hash = (prefetch-npm $frontend_lock)
  let backend_hash = (prefetch-npm $backend_lock)
  let libquery_hash = (prefetch-url (engine-url $engine_commit "libquery_engine.so.node"))
  let schema_hash = (prefetch-url (engine-url $engine_commit "schema-engine"))
  let query_hash = (prefetch-url (engine-url $engine_commit "query-engine"))

  let updated = (
    open --raw $file
    | nix-set $VERSION $tag
    | nix-set $SRC $src_hash
    | nix-set $PRISMA_COMMIT $engine_commit
    | nix-set $LIBQUERY $libquery_hash
    | nix-set $SCHEMA $schema_hash
    | nix-set $QUERY $query_hash
    | nix-set $FRONTEND_NPM $frontend_hash
    | nix-set $BACKEND_NPM $backend_hash
  )

  if (dry-run) {
    info "dry run, not writing"
    print -n $updated
    return
  }

  # The lockfiles are inputs to the hashes just computed, so they and package.nix
  # have to land together or the package is left inconsistent.
  with-rollback $file {
    cp $frontend_lock ($file | path dirname | path join "frontend-package-lock.json")
    cp $backend_lock ($file | path dirname | path join "backend-package-lock.json")
    $updated | save -f $file
    nix-build (attr)
  }
  info $"updated to ($tag)"
}
