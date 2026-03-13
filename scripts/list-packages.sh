#!/usr/bin/env bash
# Lists all packages in the flake
# Output: JSON array of package names

set -euo pipefail

nix eval --json '.#packages.x86_64-linux' --apply 'builtins.attrNames'
