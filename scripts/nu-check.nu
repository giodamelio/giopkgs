#!/usr/bin/env -S nu --no-config-file
# Parse-check nushell scripts. Used as a prek hook, mirroring shellcheck.

# Take strings and expand them against the caller's cwd. Both a `path`-typed
# argument and `nu-check` itself resolve relative paths against *this* script's
# directory, which would look for scripts/scripts/foo.nu.
def main [...files: string] {
  let bad = ($files | where {|f| not (nu-check ($f | path expand))})
  if ($bad | is-not-empty) {
    print -e $"nu-check failed:(char nl)($bad | each {|f| $'  ($f)'} | str join (char nl))"
    exit 1
  }
}
