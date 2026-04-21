#!/usr/bin/env bash
# Updates a single package using nix-update or custom update script
# Usage: update-package.sh <package_name>
# Outputs to GITHUB_STEP_SUMMARY

set -euo pipefail

package="$1"

# Get current version before update
old_version=$(nix eval --raw ".#$package.version" 2>/dev/null || echo "unknown")

# Check if package has a custom update script
if script_path=$(nix eval --raw ".#$package.updateScript" 2>/dev/null); then
  echo "Running custom update script for $package..."
  "$script_path"
else
  echo "Using default nix-update for $package..."
  nix-update --flake "$package"
fi

# Get new version after update
new_version=$(nix eval --raw ".#$package.version" 2>/dev/null || echo "unknown")

# Write job summary
if [ "$old_version" = "$new_version" ]; then
  echo "### $package" >> "$GITHUB_STEP_SUMMARY"
  echo "No update available (current version: \`$old_version\`)" >> "$GITHUB_STEP_SUMMARY"
else
  echo "### $package" >> "$GITHUB_STEP_SUMMARY"
  echo "Updated: \`$old_version\` → \`$new_version\`" >> "$GITHUB_STEP_SUMMARY"
fi
