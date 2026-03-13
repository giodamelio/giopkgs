#!/usr/bin/env nix-shell
#! nix-shell -i bash -p jq
# shellcheck shell=bash
# Update all packages in the flake

set -euo pipefail

# Get list of all packages
packages=$(nix eval .#packages.x86_64-linux --apply builtins.attrNames --json | jq -r '.[]')

echo "Updating all packages..."
for pkg in $packages; do
    echo "----------------------------------------"
    echo "Updating: $pkg"
    echo "----------------------------------------"
    if nix-update --flake "$pkg"; then
        echo "✓ Successfully updated $pkg"
    else
        echo "✗ Failed to update $pkg (exit code: $?)"
    fi
    echo
done

echo "All packages processed!"
