#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update

set -euo pipefail

# Change to the flake root directory
cd "$(dirname "$0")/../.."

# Update tidewave-cli package
# --lockfile-metadata-path points to the tidewave-cli subdirectory where Cargo.toml is located
nix-update --flake --lockfile-metadata-path tidewave-cli tidewave-cli
