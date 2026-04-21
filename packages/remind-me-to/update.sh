#!/usr/bin/env bash
set -euo pipefail

nix-update --flake remind-me-to --version=branch=main
