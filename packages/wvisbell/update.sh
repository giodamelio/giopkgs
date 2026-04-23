#!/usr/bin/env bash
set -euo pipefail

# Update wvisbell package (tracks main branch since there are no releases)
nix-update --flake --version=branch=main wvisbell
