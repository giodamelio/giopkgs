#!/usr/bin/env -S nu --no-config-file
# Package names as a JSON array, for a GitHub Actions matrix.

use archived.nu *

def main [
  --scope: string = "active" # active | all | archived-only
] {
  let all = (^nix eval --json ".#packages.x86_64-linux" --apply "builtins.attrNames" | from json)
  validate $all
  select-packages $all $scope | to json --raw
}
