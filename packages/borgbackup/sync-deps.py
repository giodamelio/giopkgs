#!/usr/bin/env python3
"""Sync the borghash/borgstore pins in package.nix to whatever the pinned
borgbackup source requires.

Reads borg's pyproject.toml at the currently-pinned borg tag, resolves each
`name ~= X.Y.Z` compatible-release constraint to the latest matching upstream
tag, and rewrites the corresponding version + hash in package.nix.
"""

import json
import os
import re
import subprocess
import sys
import urllib.request

DEPS = ["borghash", "borgstore"]
HERE = os.path.dirname(os.path.abspath(__file__))
PACKAGE_NIX = os.path.join(HERE, "package.nix")


def parse_version(text):
    try:
        return [int(x) for x in text.split(".")]
    except ValueError:
        return None


def resolve_compatible(constraint, tags):
    """Latest tag satisfying PEP 440 `~= constraint` (compatible release)."""
    base = parse_version(constraint)
    lock = base[:-1]
    candidates = []
    for tag in tags:
        v = parse_version(tag)
        if v is None:
            continue
        if v[: len(lock)] == lock and v >= base:
            candidates.append((v, tag))
    return max(candidates)[1] if candidates else None


def github_tags(repo):
    out = subprocess.run(
        ["gh", "api", f"repos/borgbackup/{repo}/tags", "--paginate", "--jq", ".[].name"],
        capture_output=True,
        text=True,
        check=True,
    )
    return out.stdout.split()


def prefetch_hash(repo, tag):
    url = f"https://github.com/borgbackup/{repo}/archive/refs/tags/{tag}.tar.gz"
    out = subprocess.run(
        ["nix", "store", "prefetch-file", "--json", "--unpack", url],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(out.stdout)["hash"]


def borg_constraints(borg_version):
    url = f"https://raw.githubusercontent.com/borgbackup/borg/{borg_version}/pyproject.toml"
    with urllib.request.urlopen(url) as resp:
        pyproject = resp.read().decode()
    constraints = {}
    for dep in DEPS:
        m = re.search(rf"{dep}\s*~=\s*([0-9.]+)", pyproject)
        if not m:
            sys.exit(f"error: no `~=` constraint for {dep} in borg {borg_version} pyproject.toml")
        constraints[dep] = m.group(1)
    return constraints


def rewrite_block(text, name, new_version, new_hash):
    anchor = text.index(f'pname = "{name}"')
    ver_re = re.compile(r'version = "([^"]*)"')
    ver_m = ver_re.search(text, anchor)
    old_version = ver_m.group(1)
    if old_version == new_version:
        return text, old_version, False
    text = text[: ver_m.start(1)] + new_version + text[ver_m.end(1) :]
    hash_re = re.compile(r'hash = "(sha256-[^"]*)"')
    hash_m = hash_re.search(text, anchor)
    text = text[: hash_m.start(1)] + new_hash + text[hash_m.end(1) :]
    return text, old_version, True


def main():
    borg_version = sys.argv[1] if len(sys.argv) > 1 else subprocess.run(
        ["nix", "eval", "--raw", ".#borgbackup.version"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()

    constraints = borg_constraints(borg_version)

    with open(PACKAGE_NIX) as f:
        text = f.read()

    for dep in DEPS:
        target = resolve_compatible(constraints[dep], github_tags(dep))
        if target is None:
            sys.exit(f"error: no {dep} tag satisfies ~= {constraints[dep]}")
        new_hash = prefetch_hash(dep, target)
        text, old_version, changed = rewrite_block(text, dep, target, new_hash)
        if changed:
            print(f"{dep}: {old_version} -> {target} (borg requires ~= {constraints[dep]})")
        else:
            print(f"{dep}: already {target} (borg requires ~= {constraints[dep]})")

    with open(PACKAGE_NIX, "w") as f:
        f.write(text)


if __name__ == "__main__":
    main()
