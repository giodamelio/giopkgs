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

1. Fetch the repo's main page to understand what it is
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

For Rust packages using `cargoHash`, same approach — use `lib.fakeHash`, build, extract the real hash.

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
- **Cargo.lock not found**: Copy `Cargo.lock` into the package directory and reference it with `cargoLock.lockFile = ./Cargo.lock;` instead of `cargoHash`
- **Go vendor issues**: Some Go projects need `proxyVendor = true`
- **Test failures**: If tests need network/external services, set `doCheck = false`

Iterate until `nix build` succeeds. Then verify the binary works:
```bash
./result/bin/<program> --help   # or --version, or whatever makes sense
```

## Step 4: Set up auto-updates

The repo has nightly auto-updates via GitHub Actions. For most packages, `nix-update` handles this automatically — no custom script needed.

### When nix-update works out of the box
If the package uses a straightforward `version` + `fetchFromGitHub` with a standard tag format (like `v${version}`), `nix-update` can handle it. Test it:

```bash
nix-update --flake <package-name>
```

If this works (even as a noop showing "already up to date"), you're done — no custom update script needed.

### When you need a custom update script
You need a custom script if:
- The version format is non-standard (e.g., includes git short hash, date-based)
- The package has multiple hashes that need coordinated updates (e.g., `hashes.json`)
- The tag format doesn't follow `v${version}` and `nix-update` can't figure it out
- Post-update processing is needed (e.g., updating a Cargo.lock)

For custom scripts, add `passthru.updateScript = ./update.sh;` and create the script. Keep it simple — use `nix-update` as the base and add post-processing only if needed:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Get the directory of this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

nix-update --flake <package-name>

# Any post-processing here
```

Make the script executable: `chmod +x packages/<name>/update.sh`

If the package started as a simple `.nix` file and now needs an update script, restructure it into a directory first.

### Verify the update script

After setting up updates, run the update mechanism once locally to confirm it works. Since the package was just created at the latest version, this should be a noop:

```bash
# If using nix-update directly (no custom script):
nix-update --flake <package-name>

# If using a custom update script:
./packages/<name>/update.sh
```

Verify it exits cleanly and doesn't make unexpected changes.

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
- [ ] Auto-update mechanism works (nix-update or custom script runs clean)
- [ ] Code is formatted with alejandra
- [ ] statix and deadnix report no issues
