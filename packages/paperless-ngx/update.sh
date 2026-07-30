#!/usr/bin/env bash
set -euo pipefail

PACKAGE_FILE="packages/paperless-ngx/package.nix"

ORIGINAL_FILE="$(mktemp)"
cp "$PACKAGE_FILE" "$ORIGINAL_FILE"
ok=false
# Any exit before `ok=true` restores package.nix. This has to be an EXIT trap,
# not ERR: an ERR trap does not fire on an explicit `exit`, so the blanked hash
# in step 1 would survive every bail-out below that uses one.
trap '[ "$ok" = true ] || cp "$ORIGINAL_FILE" "$PACKAGE_FILE"; rm -f "$ORIGINAL_FILE"' EXIT

# Update to latest commit on main branch
nix-update --flake --version=branch=main paperless-ngx

# Check if the source changed
if cmp -s "$PACKAGE_FILE" "$ORIGINAL_FILE"; then
  echo "No source changes, skipping pnpmDeps hash check."
  ok=true
  exit 0
fi

echo "Source updated, checking if pnpmDeps hash needs updating..."

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

# Step 5: Verify the package actually builds before letting the change land.
echo "Verifying paperless-ngx builds with the new hash..."
if ! nix build --no-link .#paperless-ngx; then
  echo "Build failed after updating pnpmDeps hash; reverting."
  exit 1
fi

ok=true
