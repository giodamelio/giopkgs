#!/usr/bin/env -S nu --no-config-file
# Turn the per-package artifacts CI downloaded into one commit per package, so
# `git log -- packages/<name>` reads as a version history instead of a wall of
# identical "chore: update packages".
#
# Run from the repo root, on the branch the commits should land on. The version
# pair comes from update-meta/<name>.json, which update-package.nu writes for
# every package in the matrix.

const META_DIR = "update-meta"

# packages/foo.nix and packages/foo/anything both belong to the attribute foo.
export def package-of [path: string]: nothing -> string {
  let found = ($path | parse -r '^packages/(?<name>[^/]+)')
  if ($found | is-empty) {
    error make {msg: $"($path) is not under packages/"}
  }
  $found | get name.0 | str replace -r '\.nix$' ''
}

# A hash-only refresh leaves the version untouched, and a branch-tracked package
# can move source without moving its version string, so an arrow is not always
# available.
export def message [meta: record]: nothing -> string {
  if $meta.old == $meta.new {
    $"chore\(($meta.package)): refresh dependencies"
  } else {
    $"chore\(($meta.package)): ($meta.old) -> ($meta.new)"
  }
}

def gh-output [key: string, value: string] {
  print $"($key)=($value)"
  $"($key)=($value)(char nl)" | save --append ($env.GITHUB_OUTPUT? | default "/dev/null")
}

# One list rather than rest args: nushell would otherwise claim the leading `--`
# and `-m` as flags of this command before they ever reach git.
def git-run [args: list<string>] {
  let out = (^git ...$args | complete)
  if $out.exit_code != 0 {
    error make {msg: $"git ($args | str join ' ') failed:(char nl)($out.stderr)"}
  }
}

def meta-for [package: string]: nothing -> record {
  let file = ($META_DIR | path join $"($package).json")
  if not ($file | path exists) {
    error make {msg: $"($package) has changes but no ($file) — its metadata artifact did not upload"}
  }
  open $file
}

def main [] {
  # Asking git twice, rather than parsing `status --porcelain`, avoids its rename
  # arrows and its quoting of unusual paths. The two lists stay separate because
  # reverting a failed package needs `checkout` for tracked paths and `clean` for
  # untracked ones.
  let tracked = (^git diff --name-only HEAD -- packages/ | lines)
  let untracked = (^git ls-files --others --exclude-standard -- packages/ | lines)

  let packages = ($tracked | append $untracked | each {|p| package-of $p} | uniq | sort)
  if ($packages | is-empty) {
    print "No package changes detected"
    gh-output "has_changes" "false"
    return
  }

  mut committed = 0
  for package in $packages {
    let meta = (meta-for $package)
    let mine = ($tracked | where {|p| (package-of $p) == $package})
    let mine_new = ($untracked | where {|p| (package-of $p) == $package})

    # A failed update can still leave regenerated files behind: inker's lockfiles
    # outlived a rollback that only restored package.nix, and the batch commit
    # put a 0.6.0 lockfile on main next to a 0.4.0 package.nix.
    if $meta.status == "failed" {
      print $"($package): update failed, discarding ($mine | append $mine_new | length) changed files"
      if ($mine | is-not-empty) { git-run (["checkout" "--"] | append $mine) }
      if ($mine_new | is-not-empty) { git-run (["clean" "-f" "--"] | append $mine_new) }
      continue
    }

    let msg = (message $meta)
    git-run (["add" "--"] | append $mine | append $mine_new)
    git-run ["commit" "-m" $msg]
    $committed += 1
    print $msg
  }

  gh-output "has_changes" (if $committed > 0 { "true" } else { "false" })
}
