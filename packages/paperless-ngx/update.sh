#!/usr/bin/env bash
set -euo pipefail

# Update to latest commit on main branch
nix-update --flake --version=branch=main paperless-ngx

# The pnpmDeps hash also needs updating when frontend deps change.
# Attempt a build of just the frontend deps to check if the hash is still valid.
# If it fails, extract the correct hash and patch it in.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_FILE="$DIR/package.nix"

echo "Checking if pnpmDeps hash needs updating..."
BUILD_OUTPUT=$(nix build .#paperless-ngx 2>&1) && exit 0

# Extract the correct hash from the error output
NEW_HASH=$(echo "$BUILD_OUTPUT" | grep -oP 'got: \K\S+' | head -1)
if [ -n "$NEW_HASH" ]; then
  echo "Updating pnpmDeps hash to $NEW_HASH"
  # Find the pnpmDeps hash line and replace it
  sed -i "s|hash = \"sha256-[^\"]*\"; # pnpmDeps|hash = \"$NEW_HASH\"; # pnpmDeps|" "$PACKAGE_FILE"
  echo "Hash updated. Rebuilding..."
  nix build .#paperless-ngx
else
  echo "Could not extract new hash from build output:"
  echo "$BUILD_OUTPUT" | tail -20
  exit 1
fi
