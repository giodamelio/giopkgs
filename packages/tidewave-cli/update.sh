#!/usr/bin/env bash
set -euo pipefail

PACKAGE_FILE="packages/tidewave-cli/package.nix"

# nix-update can't prefetch the src hash because it's wrapped in applyPatches
# (which produces a directory, incompatible with flat hashing).
# So we use --no-src to update version + cargo deps, then fix the src hash manually.

# Step 1: Update version and cargo deps (skip src hash)
nix-update --flake --no-src --lockfile-metadata-path tidewave-cli tidewave-cli

# Step 2: If the version changed, update the fetchFromGitHub hash
if ! git diff --quiet -- "$PACKAGE_FILE"; then
  # Extract the new rev from the file
  NEW_REV=$(grep -oP 'rev = "\K[^"]+' "$PACKAGE_FILE")
  OWNER=$(grep -oP 'owner = "\K[^"]+' "$PACKAGE_FILE")
  REPO=$(grep -oP 'repo = "\K[^"]+' "$PACKAGE_FILE")

  echo "Prefetching source hash for $OWNER/$REPO $NEW_REV..."
  SRC_HASH=$(nix-prefetch-url --unpack "https://github.com/$OWNER/$REPO/archive/$NEW_REV.tar.gz" 2>/dev/null)
  SRI_HASH=$(nix hash to-sri --type sha256 "$SRC_HASH")

  echo "Updating fetchFromGitHub hash to $SRI_HASH"
  # The fetchFromGitHub hash is the first hash after the rev line
  sed -i "/rev = \"$NEW_REV\"/,/hash = \"sha256-/{s|hash = \"sha256-[^\"]*\"|hash = \"$SRI_HASH\"|}" "$PACKAGE_FILE"
fi
