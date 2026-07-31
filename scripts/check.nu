#!/usr/bin/env -S nu --no-config-file
# What CI runs instead of a bare `nix flake check`.
#
# `nix flake check` builds every entry in `checks`, including any belonging to an
# archived package — and those can be expensive (netdata's is a NixOS VM test).
# Splitting it lets CI keep the cheap half over everything and the costly half
# over active packages only.
#
# Locally, keep running plain `nix flake check`: `checks` is deliberately left
# complete in flake.nix, so the thorough run is the default and needs no flag.

use archived.nu *

def check-names []: nothing -> list<string> {
  ^nix eval --json ".#checks.x86_64-linux" --apply "builtins.attrNames" | from json
}

def main [
  --scope: string = "active" # active | all | archived-only
] {
  let packages = (^nix eval --json ".#packages.x86_64-linux" --apply "builtins.attrNames" | from json)
  validate $packages

  # Schema and evaluation, over everything. Cheap, and it means an archived
  # package still cannot rot into a syntax error unnoticed.
  print ">> nix flake check --no-build"
  let evaluated = (^nix flake check --no-build | complete)
  if $evaluated.exit_code != 0 {
    print -e $evaluated.stderr
    error make {msg: "flake evaluation failed"}
  }

  # checks are named <package>-<test>, so a check belongs to the longest package
  # name it starts with.
  let wanted = (select-packages $packages $scope)
  let selected = (check-names | where {|c|
    $wanted | any {|p| $c starts-with $"($p)-"}
  })

  let skipped = ((check-names) | where {|c| $c not-in $selected})
  if ($skipped | is-not-empty) {
    print $">> skipping archived checks: ($skipped | str join ', ')"
  }

  if ($selected | is-empty) {
    print ">> no checks to build"
    return
  }

  print $">> building checks: ($selected | str join ', ')"
  let targets = ($selected | each {|c| $".#checks.x86_64-linux.($c)"})
  let built = (^nix build --no-link ...$targets | complete)
  if $built.exit_code != 0 {
    print -e $built.stderr
    error make {msg: "checks failed"}
  }
}
