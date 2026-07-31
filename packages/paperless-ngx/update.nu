#!/usr/bin/env -S nu --no-config-file
# nix-update tracks upstream's main branch, but it cannot see the frontend's
# pnpmDeps hash, which changes whenever the lockfile does.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const PNPM_DEPS = {attr: "hash", under: [{bind: "pnpmDeps", call: "fetchPnpmDeps"}]}

def main [] {
  let file = (pkg-file)
  let before = (open --raw $file)

  # nix-update writes the file before we get a say, so this one needs rollback.
  with-rollback $file {
    run-nix-update "--version=branch=main"

    if (open --raw $file) == $before {
      info "no source change"
    } else {
      # Rebuilding the fetcher, rather than blanking the hash in package.nix and
      # reading the build error, means the file is never on disk holding an
      # empty hash. `path:` flake refs read the working tree, so this picks up
      # the src nix-update just wrote.
      let hash = (recover-hash 'pkgs.fetchPnpmDeps {
        pnpm = pkgs.pnpm_10;
        inherit (p.frontend) pname version src;
        fetcherVersion = 3;
        hash = "";
      }')
      info $"pnpmDeps hash: ($hash)"

      open --raw $file | nix-set $PNPM_DEPS $hash | save -f $file
      nix-build (attr)
    }
  }
}
