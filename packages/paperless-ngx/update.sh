#!/usr/bin/env bash
set -euo pipefail

PACKAGE_FILE="packages/paperless-ngx/package.nix"

# Update to latest commit on main branch
nix-update --flake --version=branch=main paperless-ngx

# Check if the source changed
if ! git diff --quiet -- packages/paperless-ngx; then
  echo "Source updated, checking if pnpmDeps hash needs updating..."

  # Step 1: Blank the pnpmDeps hash to force a hash mismatch
  sed -i 's|hash = "sha256-[^"]*"; # pnpmDeps|hash = ""; # pnpmDeps|' "$PACKAGE_FILE"

  # Step 2: Build to get the correct hash from the mismatch error
  echo "Building with empty hash to get correct pnpmDeps hash..."
  BUILD_OUTPUT=$(nix build .#paperless-ngx 2>&1 || true)

  # Step 3: Extract the correct hash from the "got:" line
  NEW_HASH=$(echo "$BUILD_OUTPUT" | grep -oP 'got:\s+\Ksha256-\S+' | head -1)
  if [ -z "$NEW_HASH" ]; then
    echo "Could not extract new pnpmDeps hash from build output:"
    echo "$BUILD_OUTPUT" | tail -30
    exit 1
  fi

  # Step 4: Update the hash
  echo "Updating pnpmDeps hash to $NEW_HASH"
  sed -i "s|hash = \"\"; # pnpmDeps|hash = \"$NEW_HASH\"; # pnpmDeps|" "$PACKAGE_FILE"
else
  echo "No source changes, skipping pnpmDeps hash check."
fi
