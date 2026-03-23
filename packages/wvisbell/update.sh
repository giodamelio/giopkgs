#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update
# shellcheck shell=bash

set -euo pipefail

# Change to the flake root directory
cd "$(dirname "$0")/../.."

# Update wvisbell package (tracks main branch since there are no releases)
nix-update --flake --version=branch=main wvisbell
