# tidewave-cli Nix Package

This package builds only the `tidewave-cli` command-line tool from the [tidewave_app](https://github.com/tidewave-ai/tidewave_app) repository, excluding the Tauri desktop GUI application.

## Patches Applied

This package applies three patches to the upstream source:

1. **remove-src-tauri-from-workspace.patch** - Removes the `src-tauri` crate from the Cargo workspace to avoid building GUI dependencies
2. **remove-tao-patch.patch** - Removes the `[patch.crates-io]` section from `Cargo.toml` that overrides `tao` with a git dependency
3. **remove-tao-patch-cargolock.patch** - Removes the git-based `tao` and `tao-macros` entries from `Cargo.lock`

## Why These Patches Are Needed

The upstream repository includes a Tauri desktop application (`src-tauri`) that depends on `tao`, a windowing library. The workspace `Cargo.toml` patches `tao` to use a git fork with an unmerged branch (`wm-bundled-activation-policy`):

```toml
[patch.crates-io]
tao = { git = "https://github.com/wojtekmach/tao.git", branch = "wm-bundled-activation-policy" }
```

This creates two problems for Nix packaging:

1. **Duplicate crate names** - Both the crates.io version and git version of `tao-macros` end up in the vendor directory with the same name, causing a collision
2. **Unnecessary GUI dependencies** - The CLI tool doesn't need `tao` or any GUI dependencies

## When Can These Patches Be Removed?

These patches can be removed when **one of the following conditions is met**:

### Option 1: Upstream the tao patch (preferred)
The git patch is upstreamed to the main `tao` crate and published to crates.io, allowing the workspace to use the crates.io version.

**How to check (for future LLMs):**

1. Check if the upstream repository still has the `[patch.crates-io]` section:
   ```bash
   curl -s https://raw.githubusercontent.com/tidewave-ai/tidewave_app/main/Cargo.toml | grep -A 2 "\[patch.crates-io\]"
   ```

2. If the section is gone, patches can likely be removed. Verify by:
   ```bash
   # Clone the repo
   git clone --depth 1 https://github.com/tidewave-ai/tidewave_app
   cd tidewave_app

   # Check workspace members
   grep -A 10 "\[workspace\]" Cargo.toml

   # If src-tauri is still present, keep remove-src-tauri-from-workspace.patch
   # If no [patch.crates-io] section exists, remove the other two patches
   ```

3. Test building without patches:
   ```bash
   cd /path/to/giopkgs/packages/tidewave-cli
   # Comment out the patches in default.nix
   # Try building: nix build ../../#tidewave-cli
   ```

### Option 2: Workspace is split
The CLI tool is moved to its own separate repository or the workspace no longer includes `src-tauri`.

**How to check:**
- Visit https://github.com/tidewave-ai/tidewave_app and check if the repository structure has changed
- Look for a separate `tidewave-cli` repository
- Check if the workspace members no longer include `src-tauri`

## Maintenance Notes

When updating this package to a new version:

1. Check if patches still apply cleanly
2. Verify the upstream `Cargo.toml` and `Cargo.lock` haven't changed in ways that break the patches
3. Update the patches if necessary by:
   ```bash
   # Fetch the new source
   nix-prefetch-url --unpack https://github.com/tidewave-ai/tidewave_app/archive/refs/tags/vX.Y.Z.tar.gz

   # Apply manual edits and generate new patches
   diff -u original/Cargo.toml modified/Cargo.toml > remove-tao-patch.patch
   diff -u original/Cargo.lock modified/Cargo.lock > remove-tao-patch-cargolock.patch
   ```

## Related Issues

- TODO comment in upstream Cargo.toml: "TODO: upstream" (referring to the tao patch)
- Upstream PR/issue tracking the tao changes: https://github.com/wojtekmach/tao/tree/wm-bundled-activation-policy
