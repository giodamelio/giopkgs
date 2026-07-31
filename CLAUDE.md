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
nix build .#<name>                        # build one package
nix flake check --no-build                # evaluate every package (what the commit hook runs)
nix flake check                           # also builds the checks, i.e. every passthru.tests
nu scripts/update-package.nu <name>       # update one package, the way CI does
nu update-all.nu                          # every package, through the same dispatcher
nu scripts/tests.nu                       # offline tests for the nix-edit library
prek run --all-files                      # run every hook without committing

GIOPKGS_UPDATE_DRY_RUN=1 nu packages/<name>/update.nu   # resolve and print, write nothing
```

`prek install` runs on shell entry. The hooks are `alejandra`, `statix check`, `deadnix --fail`,
`shellcheck`, `nu-check`, `nix flake check --no-build`, and `remind-me-to` (a reminder checker that
is itself one of the packages here).

`devShells.update` is the slim subset CI enters — nushell, ast-grep, nix-update, nurl,
prefetch-npm-deps, nodejs, jq, gh, curl, python3. `devShells.default` is that plus the authoring
and linting tools, so the two cannot drift.

## Structure

`flake.nix` discovers packages with `nixpkgs.lib.filesystem.packagesFromDirectoryRecursive` over
`packages/`, so the attribute name is just the file or directory name and nothing needs
registering. The same call builds `overlays.default`.

- `packages/<name>.nix` — simple packages
- `packages/<name>/package.nix` — anything with patches, vendored lock files, or an `update.nu`

Every file is `callPackage`-style. `checks` is assembled by flattening each package's
`passthru.tests` into `<package>-<test>`, on x86_64-linux and aarch64-linux only;
`packages/netdata` is the worked example.

`.claude/skills/add-nix-package/SKILL.md` is the full walkthrough for adding a package — follow it
rather than improvising.

## Auto-updates

The nightly workflow runs `scripts/update-package.nu` per package in a matrix, uploads each result
as an artifact, commits them to a temp branch, runs `nix flake check`, and only then pushes to
main. `flake.lock` updates weekly on Sundays, an hour ahead of the nightly run.

Dispatch is by convention, in order:

1. `packages/<name>/update.nu` — run from the checkout, for packages where several hashes move
   together or a hash lives somewhere `nix-update` cannot see.
2. `passthru.updatePolicy` — `"skip"` for `overrideAttrs` wrappers that move when the flake inputs
   do and would only be corrupted by `nix-update`; `"branch"` for packages tracking a default
   branch instead of releases.
3. `nix-update --flake <name>` otherwise.

**Never declare `passthru.updateScript`.** A Nix path literal copies the script into the store as a
bare file, so it runs orphaned from its package directory — `dirname $BASH_SOURCE` becomes
`/nix/store`, and relative imports break. Four scripts silently never ran in CI because of this.
Scripts are found on disk instead, and `$env.FILE_PWD` is the package directory.

`update-package.nu` never fails its own job, so one broken upstream cannot block the others from
committing. Failures land in `update-failures/` and a terminal workflow job turns them into a red
X.

## Writing an update.nu

The shape is **compute everything, then write once**. Nothing touches `package.nix` until every
hash is known, so there is no half-written state and no rollback machinery to get wrong.

```nu
use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const SRC = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}]}

def main [] {
  let file = (pkg-file)
  # ... resolve the upstream version and every hash ...
  open --raw $file | nix-set $SRC $src_hash | save -f $file
  nix-build (attr)
}
```

`with-rollback` is only for the cases that genuinely need it: `nix-update` writing the file before
the script has a say, or a verification build after the write.

### Recovering a dependency hash

Source hashes need no build — `nurl-hash`, `prefetch-url`, `prefetch-npm`. Vendored-dependency
hashes (`cargoDeps`, `pnpmDeps`, `npmDeps`, `vendorHash`) have no prefetcher, so `recover-hash`
rebuilds the fetcher with an empty hash and reads the `got:` line. Describe the *new* source inline
and it runs before anything is written:

```nu
let cargo_hash = (recover-hash $'
  let src = pkgs.fetchFromGitHub {owner = "o"; repo = "r"; tag = "($tag)"; hash = "($src_hash)";};
  in pkgs.rustPlatform.fetchCargoVendor {inherit src; hash = "";}')
```

**Do not override the deps attribute.** `p.cargoDeps` and `p.frontend.pnpmDeps` are
input-addressed wrappers with no `outputHash` of their own — the fixed-output derivation is an
inner staging one. Overriding the wrapper hashes the wrong artifact and returns a plausible but
wrong hash with no error. Always reconstruct the fetcher.

`recover-hash` uses a `path:` flake ref, which reads the working tree directly. That means it sees
edits `nix-update` just made, and the "snapshot before building" caveat above does not apply to it.

### Editing Nix with ast-grep

`nix-edit.nu` rewrites one binding at a time. A *site* names the binding plus what disambiguates
it — the attribute name alone is never enough, since most hash sites here are spelled `hash`:

```nu
{attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}], ident: {repo: "borghash"}}
```

`under` is ordered innermost-first and walks through wrappers, so it reaches the inner fetcher of a
`src = applyPatches {src = fetchFromGitHub {…};}`. `ident` pins a sibling literal, for files with
structurally identical fetchers (borgbackup has four).

Constraints the library encodes, all of which cost real debugging:

- **Every write asserts exactly one match.** A rule that matches nothing makes `ast-grep scan -U`
  print an empty document and exit 0 — piping that to `save` truncates `package.nix` to zero bytes.
  An ambiguous or vanished site is a loud error instead.
- Rules are applied **one per invocation**; several in one `--inline-rules` emit the file once per
  rule, concatenated.
- Each step **normalises the trailing newline**, because `scan --stdin -U` appends one and they
  accumulate over a fold.
- Patterns must be `{context: '{ hash = $H; }', selector: binding}` — tree-sitter-nix rejects `$`
  in an identifier position, so a bare `hash = $H` fails to parse. The `binding` node includes the
  trailing `;`, so a fix must carry it too.
- Sites must hold a **string literal**; that is what separates `version = "0.4.0"` from
  `version = prismaEnginesCommit`.

Nushell gotchas worth knowing: `[FOO]` in a list literal is the string `"FOO"`, not the const —
use `[$FOO]`. `(...)` inside `$'...'` is a subexpression, so build regexes by concatenation. A
`path`-typed parameter is expanded relative to the *script's* directory, not the caller's cwd.

## Overriding a nixpkgs package

Wrapping a nixpkgs derivation with `overrideAttrs` is common here (`niri`, `waybar`,
`qutebrowser`, `netdata`, `parseable`). Two things that bite:

- Overriding `src` on a Rust package invalidates `cargoHash`, which is resolved against the final
  `src`. Replace `cargoDeps` outright with `rustPlatform.fetchCargoVendor { inherit src; hash = …; }`
  rather than trying to set `cargoHash`.
- Merge into `passthru`, `env`, and `meta` (`old.env // { … }`) instead of replacing them, or you
  will drop attributes the original derivation depends on.

`statix.toml` disables `repeated_keys` and `manual_inherit`.
