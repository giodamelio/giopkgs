#!/usr/bin/env -S nu --no-config-file
# Offline tests for nix-edit.nu. No network, no nix builds — string fixtures only.
use std/assert
use nix-edit.nu *

const TWO_HASHES = '{
  src = fetchFromGitHub {
    owner = "o";
    hash = "sha256-SRC";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "sha256-CARGO";
  };
}
'

const TWO_IDENTICAL = '{
  a = buildPythonPackage {
    pname = "borghash";
    src = fetchFromGitHub {
      repo = "borghash";
      hash = "sha256-AAA";
    };
  };
  b = buildPythonPackage {
    pname = "borgstore";
    src = fetchFromGitHub {
      repo = "borgstore";
      hash = "sha256-BBB";
    };
  };
}
'

const SRC = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}]}
const CARGO = {attr: "hash", under: [{bind: "cargoDeps", call: "rustPlatform.fetchCargoVendor"}]}

def "test enclosure disambiguates" [] {
  assert equal ($TWO_HASHES | nix-read $SRC) "sha256-SRC"
  assert equal ($TWO_HASHES | nix-read $CARGO) "sha256-CARGO"

  let out = ($TWO_HASHES | nix-set $SRC "sha256-NEW")
  assert str contains $out 'hash = "sha256-NEW";'
  assert str contains $out 'hash = "sha256-CARGO";'
}

# The failure that would silently destroy a package.nix: a rule that stops
# matching makes `ast-grep scan -U` emit nothing and exit 0.
def "test missing site errors rather than truncating" [] {
  let orphan = {attr: "hash", under: [{bind: "nope", call: "fetchNothing"}]}
  let err = (try { $TWO_HASHES | nix-set $orphan "x"; null } catch {|e| $e.msg })
  assert ($err != null) "expected an error for a site that matches nothing"
  assert str contains $err "expected 1"
}

def "test ambiguous site errors" [] {
  let loose = {attr: "hash"}
  let err = (try { $TWO_HASHES | nix-set $loose "x"; null } catch {|e| $e.msg })
  assert ($err != null) "expected an error for a site matching 2 nodes"
  assert str contains $err "matched 2 nodes"
}

def "test ident picks one of two identical fetchers" [] {
  let borghash = {attr: "hash", under: [{bind: "src", call: "fetchFromGitHub"}], ident: {repo: "borghash"}}
  assert equal ($TWO_IDENTICAL | nix-read $borghash) "sha256-AAA"

  let out = ($TWO_IDENTICAL | nix-set $borghash "sha256-ZZZ")
  assert str contains $out 'hash = "sha256-ZZZ";'
  assert str contains $out 'hash = "sha256-BBB";'
}

# `scan -U` appends a newline per invocation; unchecked it compounds over a fold.
def "test chained rewrites do not drift" [] {
  mut out = $TWO_HASHES
  for _ in 1..4 {
    $out = ($out | nix-set $SRC "sha256-SRC" | nix-set $CARGO "sha256-CARGO")
  }
  assert equal ($out | into binary | bytes length) ($TWO_HASHES | into binary | bytes length)
  assert equal $out $TWO_HASHES
}

def "test trailing comment survives" [] {
  let fixture = '{
  pnpmDeps = fetchPnpmDeps {
    hash = "sha256-OLD"; # pnpmDeps
  };
}
'
  let site = {attr: "hash", under: [{bind: "pnpmDeps", call: "fetchPnpmDeps"}]}
  let out = ($fixture | nix-set $site "sha256-NEW")
  assert str contains $out 'hash = "sha256-NEW"; # pnpmDeps'
}

def main [] {
  let tests = [
    ["enclosure disambiguates", {|| test enclosure disambiguates}]
    ["missing site errors rather than truncating", {|| test missing site errors rather than truncating}]
    ["ambiguous site errors", {|| test ambiguous site errors}]
    ["ident picks one of two identical fetchers", {|| test ident picks one of two identical fetchers}]
    ["chained rewrites do not drift", {|| test chained rewrites do not drift}]
    ["trailing comment survives", {|| test trailing comment survives}]
  ]

  let results = ($tests | each {|t|
    let name = ($t | get 0)
    let err = (try { do ($t | get 1); null } catch {|e| $e.msg })
    if $err == null { print $"  ok   ($name)" } else { print $"  FAIL ($name): ($err)" }
    {name: $name, err: $err}
  })

  let failed = ($results | where err != null)
  if ($failed | is-not-empty) {
    error make {msg: $"($failed | length) of ($tests | length) tests failed"}
  }
  print $"($tests | length) tests passed"
}
