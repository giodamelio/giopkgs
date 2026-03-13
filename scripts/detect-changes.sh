#!/usr/bin/env bash
# Detects which packages changed and need to be built
# Usage: detect-changes.sh <event_name> <base_ref>
# Outputs to GITHUB_OUTPUT: packages (JSON array), build_all (true/false)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

event_name="${1:-}"
base_ref="${2:-main}"

# Get all packages
all_packages=$("$SCRIPT_DIR/list-packages.sh")

# Determine base ref for comparison
if [ "$event_name" == "pull_request" ]; then
  compare_ref="origin/$base_ref"
else
  # For pushes, compare with previous commit
  compare_ref="HEAD^"
fi

# Check if flake.nix, flake.lock, or any workflow files changed
if git diff --name-only "$compare_ref" HEAD | grep -qE '^(flake\.(nix|lock)|\.github/workflows/.*)$'; then
  echo "Flake or workflow files changed, building all packages"
  echo "build_all=true" >> "$GITHUB_OUTPUT"
  echo "packages=$all_packages" >> "$GITHUB_OUTPUT"
else
  # Get changed package files
  changed_files=$(git diff --name-only "$compare_ref" HEAD | grep '^packages/' || true)

  if [ -z "$changed_files" ]; then
    echo "No package changes detected"
    echo "build_all=false" >> "$GITHUB_OUTPUT"
    echo "packages=[]" >> "$GITHUB_OUTPUT"
  else
    echo "Changed files:"
    echo "$changed_files"

    # Extract package names from changed files
    # This handles both bare .nix files and directories with package.nix
    changed_packages=$(echo "$changed_files" | \
      sed -n 's|^packages/\([^/]*\).*|\1|p' | \
      sed 's/\.nix$//' | \
      sort -u | \
      jq -R -s -c 'split("\n") | map(select(length > 0))')

    echo "Changed packages: $changed_packages"
    echo "build_all=false" >> "$GITHUB_OUTPUT"
    echo "packages=$changed_packages" >> "$GITHUB_OUTPUT"
  fi
fi
