The `node-hp-scan-to` package in this repo is failing to build. The issue is in `packages/node-hp-scan-to.nix`.

Two things are outdated:

1. **`packages/node-hp-scan-to-missing-hashes.json`** — the missing hashes file no longer matches the `yarn.lock` in the `node-hp-scan-to` v1.10.0 source.
2. **The `fetchYarnBerryDeps` hash** on line 24 of `packages/node-hp-scan-to.nix` (currently `sha256-GPdd40tYYViGXSFsZQ73yxy4JgUKqLFWMv0N2blFKEo=`) — the offline cache hash is stale.

To fix this, follow the nixpkgs yarnBerry workflow:

1. First, regenerate the missing hashes file. Build with an empty `missingHashes` (or remove it) to get the error output that lists the hashes that need to be in the JSON file. Or use the `yarn-berry-helper` tooling if available. See: https://nixos.org/manual/nixpkgs/unstable/#javascript-yarnBerry-missing-hashes
2. Once the missing hashes file is correct, set the `fetchYarnBerryDeps` hash to `lib.fakeHash`, build, let it fail with a hash mismatch, and copy the `got: sha256-...` value back in.
3. Verify the full package builds: `nix build .#node-hp-scan-to`
4. Commit and push.

The upstream source is `github:manuc66/node-hp-scan-to` tag `v1.10.0`.
