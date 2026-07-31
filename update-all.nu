#!/usr/bin/env -S nu --no-config-file
# Update every package, the same way CI does.
#
# The bash version this replaces called `nix-update --flake` on every package
# directly, bypassing custom update scripts entirely and corrupting the packages
# that opt out via updatePolicy. Going through update-package.nu means one code
# path for local runs and CI.

def main [
  --only: string # only packages whose name matches this regex
] {
  let packages = (
    ^nix eval --json ".#packages.x86_64-linux" --apply "builtins.attrNames"
    | from json
    | where {|p| $only == null or $p =~ $only}
  )

  print $"Updating ($packages | length) packages"
  for pkg in $packages {
    print $"(char nl)── ($pkg) ──"
    ^nu scripts/update-package.nu $pkg
  }

  let failures = (if ("update-failures" | path exists) { ls update-failures | get name } else { [] })
  if ($failures | is-not-empty) {
    print $"(char nl)($failures | length) package\(s) failed:"
    $failures | each {|f| print $"  ($f | path basename | str replace '.log' '')" }
  }
}
