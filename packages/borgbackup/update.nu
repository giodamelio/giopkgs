#!/usr/bin/env -S nu --no-config-file
# borg 2.0 is beta-only, and it pins borghash and borgstore with PEP 440
# compatible-release constraints in its own pyproject.toml. Bumping borg without
# moving those two in step gives a package that builds but fails at runtime, so
# they are resolved from whatever the new borg source actually asks for.

use ../../scripts/update.nu *
use ../../scripts/nix-edit.nu *

const DEPS = ["borghash" "borgstore"]

# Only the 2.0 betas; the 1.x tags would otherwise win.
const VERSION_REGEX = '^(2\.0\.0b[0-9]+)$'

def dep-site [dep: string, attr: string]: nothing -> record {
  if $attr == "version" {
    {attr: "version", under: [{kind: "rec_attrset_expression"}], ident: {pname: $dep}}
  } else {
    {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}], ident: {repo: $dep}}
  }
}

# Zero-padded so plain string ordering matches numeric version ordering.
def version-key [version: string]: nothing -> string {
  $version | split row "." | each {|part| $part | into int | fill --alignment right --character "0" --width 8} | str join "."
}

def numeric-version [version: string]: nothing -> bool {
  ($version | split row "." | all {|part| ($part | parse -r '^\d+$' | length) == 1})
}

# PEP 440 `~= X.Y.Z`: hold every component but the last, and require >= X.Y.Z.
def resolve-compatible [constraint: string, tags: list<string>]: nothing -> any {
  let parts = ($constraint | split row ".")
  let prefix = ($parts | drop 1 | str join ".")
  let floor = (version-key $constraint)

  let candidates = (
    $tags
    | where {|t| (numeric-version $t) and ($t | str starts-with $"($prefix).") and (version-key $t) >= $floor}
    | sort-by {|t| version-key $t}
  )
  if ($candidates | is-empty) { null } else { $candidates | last }
}

def main [] {
  let file = (pkg-file)

  with-rollback [$file] {
    run-nix-update $"--version-regex=($VERSION_REGEX)"

    # borg itself is a finalAttrs-style attrset; the two deps below are `rec`.
    let borg_version = (open --raw $file | nix-read {attr: "version", under: [{kind: "attrset_expression"}], ident: {pname: "borgbackup"}})
    info $"borg ($borg_version)"

    let pyproject = (fetch-text $"https://raw.githubusercontent.com/borgbackup/borg/($borg_version)/pyproject.toml")

    let resolved = ($DEPS | each {|dep|
      # The dependency may carry an extras bracket: `borgstore[rest] ~= 0.5.5`.
      # Concatenated, not interpolated: `(...)` inside $'...' is a subexpression.
      let pattern = ($dep + '(\[[^\]]*\])?\s*~=\s*(?<v>[0-9.]+)')
      let found = ($pyproject | parse -r $pattern)
      if ($found | is-empty) {
        die $"borg ($borg_version) has no `~=` constraint for ($dep)"
      }
      let constraint = ($found | get v.0)

      let tag = (resolve-compatible $constraint (gh-tags $"borgbackup/($dep)"))
      if $tag == null { die $"no ($dep) tag satisfies ~= ($constraint)" }

      info $"($dep): ~= ($constraint) -> ($tag)"
      {dep: $dep, tag: $tag, hash: (nurl-hash $"https://github.com/borgbackup/($dep)" $tag)}
    })

    let updated = ($resolved | reduce --fold (open --raw $file) {|it, acc|
      $acc
      | nix-set (dep-site $it.dep "version") $it.tag
      | nix-set (dep-site $it.dep "hash") $it.hash
    })

    if (dry-run) {
      info "dry run, not writing"
      print -n $updated
    } else {
      $updated | save -f $file
      nix-build (attr)
    }
  }
}
