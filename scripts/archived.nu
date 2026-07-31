# Reading archived.nix — the packages CI should not spend time on.
#
# Deliberately consumed only by these scripts, never by flake.nix. Keeping the
# filtering out of Nix means `checks` stays complete, so a local `nix flake
# check` covers everything by default and no impure `builtins.getEnv` escape
# hatch is needed to opt back in.
#
# Run from the repo root.

export def archived-entries []: nothing -> record {
  if not ("archived.nix" | path exists) {
    error make {msg: "no archived.nix in the current directory — run from the repo root"}
  }
  ^nix eval --json --file archived.nix | from json
}

export def archived-names []: nothing -> list<string> {
  archived-entries | columns
}

# A central list can name something that has since been renamed or deleted.
export def validate [known: list<string>] {
  let unknown = (archived-names | where {|name| $name not-in $known})
  if ($unknown | is-not-empty) {
    error make {msg: $"archived.nix names packages that do not exist: ($unknown | str join ', ')"}
  }
}

# Filter a list by scope. Does not validate — the candidate list may legitimately
# be a subset (the packages a diff touched), so call `validate` separately
# against the full package list.
export def select-packages [
  candidates: list<string>
  scope: string = "active" # active | all | archived-only
]: nothing -> list<string> {
  let all = $candidates
  let names = (archived-names)
  match $scope {
    "active" => ($all | where {|p| $p not-in $names})
    "all" => $all
    "archived-only" => ($all | where {|p| $p in $names})
    _ => (error make {msg: $"unknown scope '($scope)' — expected active, all or archived-only"})
  }
}
