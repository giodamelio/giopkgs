#!/usr/bin/env bash
# Update script for packages that track a git branch instead of a release.
# Uses nix-update's branch mode to pull the latest commit on the default branch.
# The package attr name is provided by update-package.sh via UPDATE_NIX_ATTR_PATH
# (the standard nixpkgs updateScript convention).
set -euo pipefail

exec nix-update --flake --version=branch "${UPDATE_NIX_ATTR_PATH:?UPDATE_NIX_ATTR_PATH must be set}"
