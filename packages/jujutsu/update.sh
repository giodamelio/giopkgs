#!/usr/bin/env bash
set -euo pipefail

nix-update --flake jujutsu --version=branch=main
