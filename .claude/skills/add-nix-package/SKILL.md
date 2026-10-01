---
name: add-nix-package
description: Add a new Nix package derivation to the giopkgs repository. Use this skill whenever the user wants to add, create, or package a new Nix derivation — especially when they provide a GitHub URL or project name. Also trigger when the user says things like "package X", "add X to giopkgs", "nix package for X", or passes a GitHub URL as an argument. This skill handles the full lifecycle: discovering the right builder, writing the derivation, building, and setting up auto-updates.
user_invocable: true
---

# Add Nix Package

You are adding a new package to the giopkgs Nix flake repository. This repo contains personal Nix derivations organized under `packages/`. The flake auto-discovers packages via `packagesFromDirectoryRecursive`.

## Skill arguments

The user will typically provide a GitHub URL (e.g., `https://github.com/owner/repo`) or a project name. If invoked as a slash command, the argument is the URL or name.

## Overview of steps

1. **Research** the project to determine the right packaging approach
2. **Write** the Nix derivation
3. **Build** and iterate until it succeeds
4. **Set up auto-updates** and verify the update script works
5. **Format and lint** the final result

## Step 1: Research the project

Given a GitHub URL or project name:

1. Fetch the repo's main page to understand what it is, then fetch the source to read it (see below)
2. Identify the **language and build system** — this determines which Nix builder to use:
   - **Go** → `buildGoModule` (look for `go.mod`)
   - **Rust** → `rustPlatform.buildRustPackage` (look for `Cargo.toml` / `Cargo.lock`)
   - **Node.js/npm** → `buildNpmPackage` (look for `package.json` + `package-lock.json`)
   - **Node.js/pnpm** → `stdenv.mkDerivation` with `pnpmConfigHook` (look for `pnpm-lock.yaml`)
   - **Python** → `python3.pkgs.buildPythonPackage` (look for `pyproject.toml` / `setup.py`)
   - **C/C++/generic** → `stdenv.mkDerivation` with cmake/meson/make
   - **AppImage** → `appimageTools.wrapType2`
   - **Pre-built binary** → `stdenv.mkDerivation` with simple install phase
3. Check the **latest release** (tag or version) — prefer tagged releases over branch HEADs
4. Identify the project's **license** — map it to a `lib.licenses.*` value
5. Note any **native dependencies** (openssl, pkg-config, system libraries, etc.)
6. For Rust workspace repos, identify which crate/subdir contains the target binary

### Fetch sources with Nix

To read a repository's source, prefetch it into the store rather than cloning it:

```bash
nix flake prefetch github:owner/repo --json          # default branch
nix flake prefetch github:owner/repo/<tag> --json    # a specific tag or rev
```

`storePath` in the output is the unpacked tree, ready to browse. This works where a clone does not: `jj git clone --depth 1` fails on repositories whose tags point outside the shallow history. Add `--refresh` to bypass the cache and see the latest commit.

To fetch a single file, such as a release `.deb` or tarball, use:

```bash
nix store prefetch-file --json --name <name.ext> <url>
```

It returns both `hash` (ready for `fetchurl`) and `storePath`, so you can unpack and inspect the artifact before writing the derivation. Pass `--name` when the URL has no meaningful filename, for example an opaque CDN asset id.

## Step 2: Write the derivation

### File placement

- **Simple packages** (single derivation, no patches, no extra files): `packages/<name>.nix`
- **Complex packages** (patches, lock files, custom update scripts, multiple files): `packages/<name>/package.nix`

If you're unsure, start with a simple `.nix` file — you can restructure into a directory later if needed.

### Derivation structure

All packages use the `callPackage` pattern — the file is a function taking `{ pkgs-and-libs }:` and returning a derivation.

Use `nurl` to compute the source hash:
```bash
nurl https://github.com/owner/repo <rev>
```
This outputs a `fetchFromGitHub` expression with the correct hash. Extract the hash from its output.

For Go packages, you'll need `vendorHash`. Set it to `lib.fakeHash` initially, attempt a build, then extract the correct hash from the error message.

For Rust packages, prefer `cargoHash` over `cargoLock.lockFile`. `cargoHash` is simpler (no vendored lock file to maintain) and `nix-update` can update it automatically. Use `lib.fakeHash` initially, build, extract the real hash. Only fall back to `cargoLock.lockFile` if `cargoHash` doesn't work (e.g., git dependencies in Cargo.lock that need `outputHashes`).

### Template reference

Here's the general shape for each builder type. Adapt as needed — these are starting points, not rigid templates.

**Go:**
```nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "name";
  version = "X.Y.Z";

  src = fetchFromGitHub {
    owner = "...";
    repo = "...";
    rev = "v${version}";  # or tag format used by the project
    hash = "sha256-...";
  };

  vendorHash = "sha256-...";

  ldflags = ["-s" "-w"];

  meta = {
    description = "...";
    homepage = "https://github.com/owner/repo";
    license = lib.licenses.mit;  # adjust
    maintainers = [];
    mainProgram = "...";
  };
}
```

**Rust:**
```nix
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  stdenv,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "name";
  version = "X.Y.Z";

  src = fetchFromGitHub {
    owner = "...";
    repo = "...";
    rev = "v${version}";
    hash = "sha256-...";
  };

  cargoHash = "sha256-...";

  nativeBuildInputs = [pkg-config];
  buildInputs = [openssl] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  meta = {
    description = "...";
    homepage = "https://github.com/owner/repo";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "...";
  };
}
```

**Node (npm):**
```nix
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage rec {
  pname = "name";
  version = "X.Y.Z";

  src = fetchFromGitHub {
    owner = "...";
    repo = "...";
    rev = "v${version}";
    hash = "sha256-...";
  };

  npmDepsHash = "sha256-...";

  meta = {
    description = "...";
    homepage = "https://github.com/owner/repo";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "...";
  };
}
```

Only include dependencies that are actually needed. Don't add `pkg-config`, `openssl`, or darwin frameworks unless the build requires them.

### Meta attributes

Always include:
- `description` — short, from the project's own description
- `homepage` — the project URL
- `license` — mapped to `lib.licenses.*`
- `maintainers` — use `[]` (empty)
- `mainProgram` — the binary name (for CLI tools)

Optionally:
- `platforms` — only if the package is platform-specific

## Step 3: Build and iterate

Build the package:
```bash
nix build .#<package-name>
```

Common issues and fixes:
- **Hash mismatch**: Extract the correct hash from the error output (the `got: sha256-...` line) and update the derivation
- **Missing dependencies**: Read the build error, add the required `buildInputs` or `nativeBuildInputs`
- **Rust workspace**: If the repo is a workspace, use `buildAndTestSubdir` to select the right crate, or apply patches
- **Cargo.lock not found**: Copy `Cargo.lock` into the package directory and reference it with `cargoLock.lockFile = ./Cargo.lock;` instead of `cargoHash`. This is a last resort — `cargoHash` is preferred since `nix-update` handles it automatically and there's no vendored file to maintain
- **Go vendor issues**: Some Go projects need `proxyVendor = true`
- **Test failures**: If tests need network/external services, set `doCheck = false`

Iterate until `nix build` succeeds. Then verify the binary works:
```bash
./result/bin/<program> --help   # or --version, or whatever makes sense
```

## Step 4: Set up auto-updates

The nightly workflow runs `scripts/update-package.nu <name>` for every package. It picks the first of these that applies:

1. `packages/<name>/update.nu`, if it exists
2. `passthru.updatePolicy` — `"skip"` for `overrideAttrs` wrappers that move with the flake inputs, `"branch"` for packages tracking a branch instead of releases
3. `nix-update --flake <name>` otherwise

**Never declare `passthru.updateScript`.** A path literal copies the script into the store on its own, away from its package directory, so relative imports break and the script silently never runs in CI. The dispatcher finds `update.nu` on disk instead.

### Use nix-update when it can follow the release

If the package has a literal `version` and a `fetchFromGitHub` whose tag is derived from it (like `v${version}`), `nix-update` handles it, including `cargoHash`, `vendorHash` and `npmDepsHash`. Add nothing; the dispatcher falls through to it.

### Write an update.nu when nix-update cannot

You need `packages/<name>/update.nu` when:

- The download URL cannot be derived from the version. Cap's `.deb` lives on a CDN under an opaque asset id that only appears in the release notes, so `cap-desktop/update.nu` parses it out of the release body.
- Several hashes must move together, or a hash lives somewhere `nix-update` cannot see
- The tag format is unusual, or only some releases belong to this package (Cap's repo filters on `cap-v*` tags)
- `src` is wrapped (`applyPatches`), so `nix-update` would compute dependency hashes against a stale tree

If the package started as `packages/<name>.nix`, move it to `packages/<name>/package.nix` first.

Follow the shape in CLAUDE.md, "Writing an update.nu": **compute everything, then write once**. Read the current version, return early if it matches upstream (this also skips large downloads every night), resolve every URL and hash, then edit `package.nix` with `nix-set` from `scripts/nix-edit.nu`. Honour `dry-run` by printing the result instead of saving. `packages/cap-desktop/update.nu` and `packages/tidewave-cli/update.nu` are short examples to copy.

Helpers from `scripts/update.nu` cover most needs: `gh-latest-release`, `gh-tags`, `fetch-text`, `prefetch-url` for single-file hashes, `nurl-hash` for GitHub sources, and `recover-hash` for vendored-dependency hashes. Use `die` for anything unexpected; never fall back silently.

### Verify the update mechanism

Run it the way CI does, in dry-run mode. A package created at the latest version should report "already up to date":

```bash
GIOPKGS_UPDATE_DRY_RUN=1 nu scripts/update-package.nu <name>
```

That early return means the resolving code never ran. To exercise it without editing the real script, run a copy with the version check disabled and confirm it reproduces the URL and hash already in `package.nix`:

```bash
sed 's/if $version == $current {/if false {/' packages/<name>/update.nu > packages/<name>/.update-test.nu
GIOPKGS_UPDATE_DRY_RUN=1 nu packages/<name>/.update-test.nu
rm packages/<name>/.update-test.nu
```

Adjust the `sed` pattern to match the script's own up-to-date check.

## Step 5: Format and lint

Before finishing, run the formatting and linting tools that the git hooks enforce:

```bash
alejandra packages/<name>.nix   # or packages/<name>/package.nix
statix check packages/<name>.nix
deadnix packages/<name>.nix
```

Fix any issues they flag.

## Final checklist

- [ ] Derivation builds successfully with `nix build .#<name>`
- [ ] Binary runs (if applicable)
- [ ] `nix flake check --no-build` passes
- [ ] `GIOPKGS_UPDATE_DRY_RUN=1 nu scripts/update-package.nu <name>` runs clean, and an `update.nu` reproduces the current hashes when forced
- [ ] Code is formatted with alejandra
- [ ] statix and deadnix report no issues
