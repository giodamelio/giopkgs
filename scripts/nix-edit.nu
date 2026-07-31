# Reading and rewriting scalar bindings in Nix files, via ast-grep.
#
# A *site* names one binding plus the structure that disambiguates it:
#
#   { attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}] }
#
# `under` is ordered innermost-first; each entry is either {bind, call} for a
# binding whose value is a fetcher call, or {kind} for a bare node kind.
# `ident` pins sibling literals on the innermost enclosure, for files that
# contain structurally identical fetchers (borgbackup has four).
#
# Matching on the attribute name alone is never enough: 31 of ~55 hash sites in
# this repo are spelled `hash`.

# tree-sitter-nix rejects `$` in an identifier position, so a bare `hash = $V`
# pattern fails to parse. Wrapping it in an attrset and selecting the binding is
# the documented workaround.
def binding-pattern [body: string]: nothing -> record {
  {pattern: {context: $"{ ($body) }", selector: "binding"}}
}

def enclosure [entry: record]: nothing -> record {
  if "kind" in $entry {
    {kind: $entry.kind, stopBy: "end"}
  } else {
    (binding-pattern $"($entry.bind) = ($entry.call) { $$$ };") | insert stopBy "end"
  }
}

# Compose `under` into nested `inside:` clauses, innermost first.
def nest [under: list<record>, ident: record]: nothing -> record {
  if ($under | is-empty) { return {} }

  mut inner = (enclosure ($under | first))

  if ($ident | is-not-empty) {
    let keys = ($ident | columns)
    if ($keys | length) > 1 {
      error make {msg: $"site ident supports one key, got ($keys | str join ', ')"}
    }
    let k = ($keys | first)
    $inner = ($inner | insert has ((binding-pattern $'($k) = "($ident | get $k)";') | insert stopBy "end"))
  }

  let outer = (nest ($under | skip 1) {})
  if ($outer | is-empty) { {inside: $inner} } else { {inside: ($inner | merge $outer)} }
}

# Rule as a record, serialised with `to yaml`. Never build this by string
# interpolation: discriminators legitimately contain `$`, `{` and `}`.
export def site-rule [site: record, fix?: string]: nothing -> string {
  let under = ($site | get -o under | default [])
  let ident = ($site | get -o ident | default {})

  # `under: [FOO]` in a list literal is the *string* "FOO"; referring to another
  # const needs `[$FOO]`. Catch that here rather than deep in rule construction.
  let bad = ($under | where {|e| ($e | describe) !~ '^record'})
  if ($bad | is-not-empty) {
    error make {msg: $"site 'under' entries must be records, got ($bad | to nuon) — did you mean [$($bad | first)]?"}
  }

  mut rule = ((binding-pattern $"($site.attr) = $V;") | merge (nest $under $ident))
  mut doc = {id: "giopkgs", language: "nix", rule: $rule}
  if $fix != null { $doc = ($doc | insert fix $fix) }
  $doc | to yaml
}

def scan [src: string, rule: string, --fix]: nothing -> record {
  let args = if $fix { [--stdin -U --inline-rules $rule] } else { [--stdin --json=compact --inline-rules $rule] }
  let out = ($src | ^ast-grep scan ...$args | complete)
  if $out.exit_code != 0 {
    error make {msg: $"ast-grep failed: ($out.stderr)"}
  }
  $out
}

# Every match of `site`, as ast-grep JSON objects.
export def nix-matches [site: record]: string -> list {
  (scan $in (site-rule $site)).stdout | from json
}

# The literal at `site`, quotes stripped. Errors unless exactly one match.
export def nix-read [site: record]: string -> string {
  let hits = ($in | nix-matches $site)
  if ($hits | length) != 1 {
    error make {msg: $"site ($site.attr) matched ($hits | length) nodes, expected 1"}
  }
  $hits.0.metaVariables.single.V.text | str trim --char '"'
}

# Rewrite the literal at `site`. Pure: string in, string out, disk untouched.
export def nix-set [site: record, value: string]: string -> string {
  let src = $in

  # Assert before rewriting. A rule that matches nothing makes `scan -U` print
  # an empty document and exit 0, which would silently truncate the file.
  let hits = ($src | nix-matches $site)
  if ($hits | length) != 1 {
    error make {
      msg: $"site '($site.attr)' matched ($hits | length) nodes, expected 1 — ($site | to nuon)"
    }
  }

  # The `binding` node spans the trailing `;`, so the fix has to carry it too.
  let out = (scan $src (site-rule $site $'($site.attr) = "($value)";') --fix)
  if ($out.stdout | is-empty) {
    error make {msg: $"ast-grep produced no output for site '($site.attr)'"}
  }

  # `scan -U` appends a newline per invocation and they accumulate over a chain.
  $"($out.stdout | str trim --right --char (char nl))(char nl)"
}
