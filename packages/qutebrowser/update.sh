#!/usr/bin/env bash
# Update qutebrowser package with short hash in version
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FILE="$SCRIPT_DIR/package.nix"

# Run nix-update from repo root
cd "$REPO_ROOT"
nix-update --flake qutebrowser --version branch=main

# Extract the new rev and append short hash to version
REV=$(grep -oP 'rev = "\K[^"]+' "$FILE")
SHORT_HASH=${REV:0:7}

# Append short hash to version if not already present
sed -i -E "s/(version = \"[^\"]+)-([0-9]{4}-[0-9]{2}-[0-9]{2})\";/\1-\2-${SHORT_HASH}\";/" "$FILE"

echo "Updated with short hash: $SHORT_HASH"
