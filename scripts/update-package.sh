#!/usr/bin/env bash
# Updates a single package using nix-update or custom update script
# Usage: update-package.sh <package_name>
# Outputs to GITHUB_STEP_SUMMARY

set -euo pipefail

package="$1"

# Get current version before update
old_version=$(nix eval --raw ".#$package.version" 2>/dev/null || echo "unknown")

# Run the update, but don't fail the job on transient errors (e.g. crates.io rate limiting).
# This ensures successful package updates still get collected and committed.
update_failed=false

# Check if package has a custom update script
if script_path=$(nix eval --raw ".#$package.updateScript" 2>/dev/null); then
  echo "Running custom update script for $package..."
  if ! "$script_path"; then
    update_failed=true
  fi
else
  echo "Using default nix-update for $package..."
  if ! nix-update --flake "$package"; then
    update_failed=true
  fi
fi

# Get new version after update
new_version=$(nix eval --raw ".#$package.version" 2>/dev/null || echo "unknown")

# Write job summary
echo "### $package" >> "$GITHUB_STEP_SUMMARY"
if [ "$update_failed" = true ]; then
  echo "**Update failed** (current version: \`$old_version\`)" >> "$GITHUB_STEP_SUMMARY"
  echo "Check the job logs for details." >> "$GITHUB_STEP_SUMMARY"
elif [ "$old_version" = "$new_version" ]; then
  echo "No update available (current version: \`$old_version\`)" >> "$GITHUB_STEP_SUMMARY"
else
  echo "Updated: \`$old_version\` → \`$new_version\`" >> "$GITHUB_STEP_SUMMARY"
fi
