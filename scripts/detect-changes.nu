#!/usr/bin/env -S nu --no-config-file
# Work out which packages CI needs to build. Writes to $GITHUB_OUTPUT.

def all-packages []: nothing -> list<string> {
  ^nix eval --json ".#packages.x86_64-linux" --apply "builtins.attrNames" | from json
}

def gh-output [key: string, value: string] {
  print $"($key)=($value)"
  $"($key)=($value)(char nl)" | save --append ($env.GITHUB_OUTPUT? | default "/dev/null")
}

def main [
  event_name: string = "" # the triggering GitHub event
  base_ref: string = "main" # the PR base branch
] {
  let compare = if $event_name == "pull_request" { $"origin/($base_ref)" } else { "HEAD^" }
  let changed = (^git diff --name-only $compare HEAD | lines)

  # A flake or workflow change can affect every package, so rebuild all of them.
  if ($changed | any {|f| $f =~ '^(flake\.(nix|lock)|\.github/workflows/)'}) {
    print "Flake or workflow files changed, building all packages"
    gh-output "build_all" "true"
    gh-output "packages" (all-packages | to json --raw)
    return
  }

  # packages/foo.nix and packages/foo/anything both belong to the attribute foo.
  let packages = (
    $changed
    | where {|f| $f starts-with "packages/"}
    | each {|f| $f | parse -r '^packages/(?<name>[^/]+)' | get name.0 | str replace -r '\.nix$' ''}
    | uniq
  )

  if ($packages | is-empty) {
    print "No package changes detected"
  } else {
    print $"Changed packages: ($packages | str join ', ')"
  }
  gh-output "build_all" "false"
  gh-output "packages" ($packages | to json --raw)
}
