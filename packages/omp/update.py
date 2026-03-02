#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 nurl curl jq nix

"""
Update omp package to a new commit.

Usage:
    ./update.py              # Update to latest main
    ./update.py <ref>        # Update to commit/branch/tag
    ./update.py --resolve    # Just print resolved commit SHA

Computes hashes using:
- nurl for source (direct prefetch)  
- nix build for FODs with hash extraction from errors
"""

import json
import re
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
HASHES_FILE = SCRIPT_DIR / "hashes.json"
FLAKE_ROOT = SCRIPT_DIR.parent.parent
PLACEHOLDER = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="


def log(msg: str):
    print(msg, file=sys.stderr)


def run(cmd: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess:
    """Run command, return result."""
    return subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)


def github(path: str) -> dict:
    """GitHub API request."""
    r = run(["curl", "-fsSL", f"https://api.github.com{path}"])
    if r.returncode != 0:
        raise RuntimeError(f"GitHub API failed: {path}")
    return json.loads(r.stdout)


def resolve_ref(owner: str, repo: str, ref: str) -> str:
    """Resolve ref to commit SHA."""
    for getter in [
        lambda: github(f"/repos/{owner}/{repo}/branches/{ref}")["commit"]["sha"],
        lambda: (lambda o: github(f"/repos/{owner}/{repo}/git/tags/{o['sha']}")["object"]["sha"] 
                 if o["type"] == "tag" else o["sha"])(
            github(f"/repos/{owner}/{repo}/git/refs/tags/{ref}")["object"]),
        lambda: github(f"/repos/{owner}/{repo}/commits/{ref}")["sha"],
    ]:
        try:
            return getter()
        except:
            pass
    raise ValueError(f"Cannot resolve: {ref}")


def extract_hash_mismatches(output: str) -> dict[str, str]:
    """
    Extract all hash mismatches from nix build output.
    Returns dict mapping derivation name to correct hash.
    """
    results = {}
    
    # Split by 'error:' and parse each block
    for block in output.split('error:'):
        drv_match = re.search(r'/([^/]+)\.drv', block)
        hash_match = re.search(r'got:\s+(sha256-[A-Za-z0-9+/]+=*)', block)
        if drv_match and hash_match:
            drv_name = drv_match.group(1)
            correct_hash = hash_match.group(1)
            results[drv_name] = correct_hash
    
    return results


def prefetch_src(owner: str, repo: str, rev: str) -> str:
    """Use nurl to get source hash."""
    log("Computing srcHash with nurl...")
    r = run(["nurl", f"https://github.com/{owner}/{repo}", rev])
    if r.returncode != 0:
        raise RuntimeError(f"nurl failed: {r.stderr}")
    m = re.search(r'hash\s*=\s*"(sha256-[^"]+)"', r.stdout)
    if not m:
        raise RuntimeError("Cannot parse nurl output")
    return m.group(1)


def write_hashes(hashes: dict):
    """Write hashes.json and stage for git."""
    with open(HASHES_FILE, "w") as f:
        json.dump(hashes, f, indent=2)
        f.write("\n")
    run(["git", "add", str(HASHES_FILE)], cwd=FLAKE_ROOT)


def apply_hash_fixes(hashes: dict, mismatches: dict[str, str], current_system: str) -> bool:
    """
    Apply hash fixes from mismatch dict.
    Returns True if any changes were made.
    """
    changed = False
    
    for drv_name, correct_hash in mismatches.items():
        if "cargo-deps" in drv_name:
            if hashes["cargoHash"] != correct_hash:
                log(f"  cargoHash: {correct_hash}")
                hashes["cargoHash"] = correct_hash
                changed = True
        elif "node_modules" in drv_name:
            if hashes["nodeModulesHashes"].get(current_system) != correct_hash:
                log(f"  nodeModulesHashes.{current_system}: {correct_hash}")
                hashes["nodeModulesHashes"][current_system] = correct_hash
                changed = True
    
    return changed


def update_hashes(owner: str, repo: str, rev: str) -> dict:
    """Compute all hashes for a commit."""
    with open(HASHES_FILE) as f:
        hashes = json.load(f)
    
    # Get current system
    r = run(["nix", "eval", "--raw", "--impure", "--expr", "builtins.currentSystem"])
    current_system = r.stdout.strip()
    log(f"System: {current_system}")
    
    # Update metadata
    hashes["owner"] = owner
    hashes["repo"] = repo  
    hashes["rev"] = rev
    hashes["version"] = rev[:7]
    
    # 1. Source hash (direct prefetch with nurl)
    hashes["srcHash"] = prefetch_src(owner, repo, rev)
    log(f"  srcHash: {hashes['srcHash']}")
    
    # 2. Set placeholder hashes for FODs
    hashes["cargoHash"] = PLACEHOLDER
    hashes["nodeModulesHashes"][current_system] = PLACEHOLDER
    write_hashes(hashes)
    
    # 3. Iteratively build and fix hashes until success
    log("Computing FOD hashes (cargo, node_modules)...")
    max_iterations = 5
    for i in range(max_iterations):
        r = run(["nix", "build", ".#omp", "--no-link"], cwd=FLAKE_ROOT)
        
        if r.returncode == 0:
            log("Build successful!")
            break
        
        # Extract all hash mismatches
        mismatches = extract_hash_mismatches(r.stderr)
        
        if not mismatches:
            log("Build failed but no hash mismatches found:")
            log(r.stderr[-2000:])
            raise RuntimeError("Build failed without hash mismatch")
        
        # Apply fixes
        if apply_hash_fixes(hashes, mismatches, current_system):
            write_hashes(hashes)
        else:
            log("No new hashes to apply, but build still failing:")
            log(r.stderr[-1000:])
            break
    else:
        log(f"WARNING: Build still failing after {max_iterations} iterations")
    
    return hashes


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    resolve_only = "--resolve" in sys.argv
    
    with open(HASHES_FILE) as f:
        current = json.load(f)
    
    owner = current.get("owner", "giodamelio")
    repo = current.get("repo", "oh-my-pi")
    ref = args[0] if args else "main"
    
    log(f"Resolving {ref}...")
    rev = resolve_ref(owner, repo, ref)
    log(f"  {rev[:7]} ({rev})")
    
    if resolve_only:
        print(rev)
        return
    
    hashes = update_hashes(owner, repo, rev)
    write_hashes(hashes)
    log(f"\nUpdated: {HASHES_FILE}")


if __name__ == "__main__":
    main()
