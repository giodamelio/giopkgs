#!/usr/bin/env bash
set -euo pipefail

PACKAGE_FILE="packages/paperless-ngx/package.nix"

# Update to latest commit on main branch
nix-update --flake --version=branch=main paperless-ngx

# Check if the source changed
if ! git diff --quiet -- packages/paperless-ngx; then
  echo "Source updated, checking if pnpmDeps hash needs updating..."

  ORIGINAL_FILE="$(mktemp)"
  cp "$PACKAGE_FILE" "$ORIGINAL_FILE"
  # Never leave a blanked hash behind: any non-zero exit restores the original.
  trap 'cp "$ORIGINAL_FILE" "$PACKAGE_FILE"; rm -f "$ORIGINAL_FILE"' ERR

  # Step 1: Blank the pnpmDeps hash to force a hash mismatch
  sed -i 's|hash = "sha256-[^"]*"; # pnpmDeps|hash = ""; # pnpmDeps|' "$PACKAGE_FILE"

  # Step 2: Build only the deps derivation, so an unrelated failure further up
  # the build can't masquerade as a missing hash.
  echo "Building with empty hash to get correct pnpmDeps hash..."
  BUILD_OUTPUT=$(nix build .#paperless-ngx.frontend.pnpmDeps 2>&1 || true)

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

  trap - ERR
  rm -f "$ORIGINAL_FILE"

  # Step 5: Verify the package actually builds before letting the change land.
  echo "Verifying paperless-ngx builds with the new hash..."
  if ! nix build --no-link .#paperless-ngx; then
    echo "Build failed after updating pnpmDeps hash; reverting."
    git checkout -- packages/paperless-ngx
    exit 1
  fi
else
  echo "No source changes, skipping pnpmDeps hash check."
fi
