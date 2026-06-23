#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

nix-update --flake borgbackup --version-regex '^(2\.0\.0b[0-9]+)$'

# Pin borghash/borgstore to whatever the (possibly bumped) borg source requires.
borg_version="$(nix eval --raw .#borgbackup.version)"
python3 "$DIR/sync-deps.py" "$borg_version"
