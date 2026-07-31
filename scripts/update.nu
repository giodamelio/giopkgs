# Shared helpers for packages/<name>/update.nu.
#
# Everything resolves from $env.FILE_PWD, which nushell binds to the *calling*
# script's directory. Update scripts run from the checkout, so that is the
# package directory — no store paths, and nothing depends on the caller's cwd.

# --- context ---------------------------------------------------------------

export def pkg-dir []: nothing -> path {
  let dir = $env.FILE_PWD
  if not ($dir | path join "package.nix" | path exists) {
    error make {msg: $"no package.nix in ($dir) — is this script inside its package directory?"}
  }
  $dir
}

export def pkg-file []: nothing -> path {
  pkg-dir | path join "package.nix"
}

export def repo-root []: nothing -> path {
  let root = (pkg-dir | path dirname | path dirname)
  if not ($root | path join "flake.nix" | path exists) {
    error make {msg: $"no flake.nix at ($root)"}
  }
  $root
}

export def attr []: nothing -> string {
  $env.UPDATE_NIX_ATTR_PATH? | default (pkg-dir | path basename)
}

# --- output ----------------------------------------------------------------

export def info [msg: string] {
  print -e $">> ($msg)"
}

export def die [msg: string] {
  error make {msg: $msg}
}

export def dry-run []: nothing -> bool {
  ($env.GIOPKGS_UPDATE_DRY_RUN? | default "0") == "1"
}

def tail-of [text: string, n: int = 30]: nothing -> string {
  $text | lines | last $n | str join (char nl)
}

# --- upstream --------------------------------------------------------------

export def fetch-text [url: string]: nothing -> string {
  http get --raw $url
}

export def gh-latest-release [repo: string]: nothing -> record {
  let rel = (http get $"https://api.github.com/repos/($repo)/releases/latest")
  {
    tag: $rel.tag_name
    version: ($rel.tag_name | str replace -r '^v' '')
    assets: $rel.assets
  }
}

export def gh-tags [repo: string, --match: string]: nothing -> list<string> {
  let tags = (http get $"https://api.github.com/repos/($repo)/tags" | get name)
  if $match == null { $tags } else { $tags | where {|t| $t =~ $match} }
}

# --- source hashes (no build) ----------------------------------------------

export def prefetch-url [url: string, --unpack, --name: string]: nothing -> string {
  mut args = [store prefetch-file --json]
  if $name != null { $args = ($args | append [--name $name]) }
  if $unpack { $args = ($args | append "--unpack") }
  ^nix ...$args $url | from json | get hash
}

# The fetched file itself, for callers that must inspect it rather than just
# hash it (parseable checks upstream's sha1 pin before trusting the bundle).
export def prefetch-store-path [url: string]: nothing -> path {
  ^nix store prefetch-file --json $url | from json | get storePath
}

export def sha1-of [file: path]: nothing -> string {
  ^nix hash file --type sha1 --base16 $file | str trim
}

export def nurl-hash [url: string, rev: string]: nothing -> string {
  let out = (^nurl $url $rev | complete)
  if $out.exit_code != 0 { die $"nurl failed: (tail-of $out.stderr)" }
  $out.stdout | parse -r 'hash = "(?<h>[^"]+)"' | get h.0
}

export def prefetch-npm [lockfile: path]: nothing -> string {
  ^prefetch-npm-deps $lockfile | lines | last
}

# --- dependency hashes (build required) ------------------------------------

# Recover the hash of a vendored-dependency FOD (cargoDeps, pnpmDeps, npmDeps,
# vendorHash) by building it with an empty hash and reading the `got:` line.
#
# `expr` is evaluated with `f`, `pkgs` and `p` in scope. Build `src` inline from
# values already computed rather than reading it off `p`, so this can run before
# anything has been written to disk.
#
# Do NOT reach for `p.cargoDeps.overrideAttrs {outputHash = ...}`: that attribute
# is an input-addressed wrapper, not the fixed-output derivation (the FOD is an
# inner cargo-deps-vendor-staging). Overriding it hashes the wrong artifact and
# returns a plausible but wrong hash, with no error. Reconstruct the fetcher.
export def recover-hash [expr: string, --system: string = "x86_64-linux"]: nothing -> string {
  let preamble = $'let
  f = builtins.getFlake "path:(repo-root)";
  pkgs = import f.inputs.nixpkgs { system = "($system)"; };
  p = f.packages.($system)."(attr)";
in
'
  let out = (^nix build --impure --no-link --expr ($preamble + $expr) | complete)
  let got = ($out.stderr | parse -r 'got:\s+(?<h>\S+)' | get -o h.0)
  if ($got | is-empty) {
    die $"could not recover a hash from the build output:\n(tail-of $out.stderr)"
  }
  $got
}

# --- nix -------------------------------------------------------------------

export def nix-eval-raw [attrpath: string]: nothing -> string {
  let out = (^nix eval --raw $"(repo-root)#($attrpath)" | complete)
  if $out.exit_code != 0 { die $"nix eval ($attrpath) failed: (tail-of $out.stderr)" }
  $out.stdout
}

export def nix-build [attrpath: string] {
  let out = (^nix build --no-link $"(repo-root)#($attrpath)" | complete)
  if $out.exit_code != 0 {
    die $"($attrpath) failed to build:\n(tail-of $out.stderr)"
  }
}

export def run-nix-update [...args: string] {
  cd (repo-root)
  let out = (^nix-update --flake ...$args (attr) | complete)
  if $out.exit_code != 0 { die $"nix-update failed:\n(tail-of $out.stderr)" }
}

# --- flow ------------------------------------------------------------------

# Restore `file` if `body` fails. Only needed where something outside our
# control mutates it first (nix-update), or where a verification build runs
# after the write — a pure compute-then-write-once script needs no rollback.
export def with-rollback [file: path, body: closure] {
  let backup = (open --raw $file)
  try {
    do $body
  } catch {|e|
    $backup | save -f $file
    error make {msg: $"rolled back ($file | path basename): ($e.msg)"}
  }
}
