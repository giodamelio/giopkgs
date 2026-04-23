#!/usr/bin/env bash
# No-op update script for packages that track nixpkgs.
# These packages are overrideAttrs wrappers — they update when flake inputs update.
echo "Package tracks nixpkgs, skipping nix-update"
