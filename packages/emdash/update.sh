#!/usr/bin/env bash
set -euo pipefail

nix-update --flake emdash --version=branch=main
