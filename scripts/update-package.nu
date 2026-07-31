#!/usr/bin/env -S nu --no-config-file
# Update a single package. Run from the repo root.
#
# Dispatch, in order:
#   1. packages/<attr>/update.{nu,sh}  — run it, from the checkout
#   2. passthru.updatePolicy           — "skip" | "branch"
#   3. otherwise                       — nix-update --flake <attr>
#
# Running the script from the checkout rather than from passthru.updateScript is
# what fixes the long-standing bug where `dirname $BASH_SOURCE` resolved to
# /nix/store, because a path literal in passthru copies the script there as a
# bare file, orphaned from its package directory.
#
# Never fails the job: one flaky upstream must not stop the other packages from
# being committed. Failures are recorded in update-failures/ instead, which a
# terminal CI job turns into a red X.

def nix-eval-or [attrpath: string, fallback: string]: nothing -> string {
  let out = (^nix eval --raw $".#($attrpath)" | complete)
  if $out.exit_code == 0 { $out.stdout } else { $fallback }
}

def summary [text: string] {
  $"($text)(char nl)" | save --append ($env.GITHUB_STEP_SUMMARY? | default "/dev/null")
}

def dispatch [package: string]: nothing -> record {
  let nu_script = $"packages/($package)/update.nu"
  let sh_script = $"packages/($package)/update.sh"

  if ($nu_script | path exists) {
    print $"Running ($nu_script)"
    return (with-env {UPDATE_NIX_ATTR_PATH: $package} { ^nu $nu_script | complete })
  }

  if ($sh_script | path exists) {
    print $"Running ($sh_script)"
    return (with-env {UPDATE_NIX_ATTR_PATH: $package} { ^bash $sh_script | complete })
  }

  match (nix-eval-or $"($package).passthru.updatePolicy" "") {
    "skip" => {
      print $"($package) opts out of automatic updates"
      {exit_code: 0, stdout: "", stderr: ""}
    }
    "branch" => {
      print $"Updating ($package) from its default branch"
      ^nix-update --flake --version=branch $package | complete
    }
    _ => {
      print $"Updating ($package) with nix-update"
      ^nix-update --flake $package | complete
    }
  }
}

def main [package: string] {
  let old = (nix-eval-or $"($package).version" "unknown")
  let result = (dispatch $package)

  if ($result.stdout | is-not-empty) { print $result.stdout }
  if ($result.stderr | is-not-empty) { print -e $result.stderr }

  let new = (nix-eval-or $"($package).version" "unknown")

  summary $"### ($package)"
  if $result.exit_code != 0 {
    # The old bash version reported only "check the job logs", which is why the
    # /nix/store path bug went unnoticed for so long. Put the reason in the
    # summary, and leave a marker for the terminal job to find.
    let tail = ($result.stderr | lines | last 20 | str join (char nl))
    summary $"**Update failed** \(current version: `($old)`)"
    summary $"```(char nl)($tail)(char nl)```"
    mkdir update-failures
    $"($package) exited ($result.exit_code)(char nl)($tail)(char nl)" | save -f $"update-failures/($package).log"
    print -e $"($package): update failed"
  } else if $old == $new {
    summary $"No update available \(current version: `($old)`)"
  } else {
    summary $"Updated: `($old)` → `($new)`"
  }
}
