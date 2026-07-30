# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal Nix flake of derivations that haven't been upstreamed to nixpkgs. It exposes every
package both as `packages.<system>.<name>` and via `overlays.default`, builds them in CI, pushes
them to the `giopkgs` Cachix cache, and updates them nightly.

## Version control: jj, not git

This repo uses [Jujutsu](https://jj-vcs.github.io/jj/) on top of git. Use `jj status`, `jj diff`,
`jj describe -m`, `jj new`. Files are auto-tracked, so there is no `jj add`.

Nix reads the *git* tree, so a newly created file is invisible to `nix build` — it fails with
"does not provide attribute" — until jj snapshots the working copy. Any jj command does that, so
run `jj status` after creating a file and before building it.

CI is plain git; the workflows commit and push directly.

## Commands

`direnv` loads the dev shell (`use flake`); otherwise `nix develop`. It provides `nix-init`,
`nurl`, `nix-update`, `crate2nix`, `prek`, `alejandra`, `shellcheck`, `statix`, `deadnix`.

```bash
nix build .#<name>              # build one package
nix flake check --no-build      # evaluate every package (what the commit hook runs)
nix flake check                 # also builds the checks, i.e. every passthru.tests
./scripts/list-packages.sh      # JSON array of package names
./update-all.sh                 # nix-update across every package
prek run --all-files            # run every hook without committing

# update one package the way CI does; the var is required, it writes a job summary
GITHUB_STEP_SUMMARY=/dev/null ./scripts/update-package.sh <name>
```

`prek install` runs on shell entry. The hooks are `alejandra`, `statix check`, `deadnix --fail`,
`shellcheck`, `nix flake check --no-build`, and `remind-me-to` (a reminder checker that is itself
one of the packages here).

## Structure

`flake.nix` discovers packages with `nixpkgs.lib.filesystem.packagesFromDirectoryRecursive` over
`packages/`, so the attribute name is just the file or directory name and nothing needs
registering. The same call builds `overlays.default`.

- `packages/<name>.nix` — simple packages
- `packages/<name>/package.nix` — anything with patches, vendored lock files, or an `update.sh`

Every file is `callPackage`-style. `checks` is assembled by flattening each package's
`passthru.tests` into `<package>-<test>`, on x86_64-linux and aarch64-linux only;
`packages/netdata` is the worked example.

`.claude/skills/add-nix-package/SKILL.md` is the full walkthrough for adding a package — follow it
rather than improvising.

## Auto-updates

The nightly workflow runs `scripts/update-package.sh` per package in a matrix, uploads each result
as an artifact, commits them to a temp branch, runs `nix flake check`, and only then pushes to
main. `flake.lock` updates weekly on Sundays, an hour ahead of the nightly run.

`update-package.sh` dispatches to `passthru.updateScript` if the package defines one and falls back
to `nix-update --flake <name>`. Two conventions matter:

- `scripts/skip-update.sh` — for `overrideAttrs` wrappers around a nixpkgs package, which update
  when the flake inputs do and would only be corrupted by `nix-update`.
- A package-local `update.sh` — when several hashes have to move together, or when a hash lives
  somewhere `nix-update` cannot see.

## Writing an update.sh

Several scripts recover a hash by blanking it, building, and reading the real value off the `got:`
line. A failure anywhere in that window must not leave the blanked hash on disk.

Restore from an **EXIT** trap gated on a success flag, and take the backup before the first thing
that mutates the file (usually `nix-update`) so the same trap can also undo a version bump:

```bash
backup="$(mktemp)"
cp "$PKG" "$backup"
ok=false
trap '[ "$ok" = true ] || cp "$backup" "$PKG"; rm -f "$backup"' EXIT

# blank the hash, build, write the real hash, verify the package builds

ok=true
```

Do not use an `ERR` trap for this. `ERR` does not fire on an explicit `exit`. It appears to work
because `set -euo pipefail` aborts at a failing `hash=$(... | grep ...)` before reaching the
`exit 1` below it, and `ERR` does fire on that — but the safety is invisible and one `|| true`
added to the extraction silently removes it.

Build only the deps derivation (`.#pkg.cargoDeps`, `.#pkg.frontend.pnpmDeps`) when fishing for a
hash, so an unrelated failure further up the build cannot masquerade as a missing hash. Prefer
comparing against the backup with `cmp` over shelling out to `git diff` to detect changes.

## Overriding a nixpkgs package

Wrapping a nixpkgs derivation with `overrideAttrs` is common here (`niri`, `waybar`,
`qutebrowser`, `netdata`, `parseable`). Two things that bite:

- Overriding `src` on a Rust package invalidates `cargoHash`, which is resolved against the final
  `src`. Replace `cargoDeps` outright with `rustPlatform.fetchCargoVendor { inherit src; hash = …; }`
  rather than trying to set `cargoHash`.
- Merge into `passthru`, `env`, and `meta` (`old.env // { … }`) instead of replacing them, or you
  will drop attributes the original derivation depends on.

`statix.toml` disables `repeated_keys` and `manual_inherit`.
