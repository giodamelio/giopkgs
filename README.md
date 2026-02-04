# Gio's Packages

Here are some Nix derivations for some random projects that I consume. Things I haven't had the time/reason to clean up and upstream.

There is the flake that exposes them all as packages and as an overlay, and they are all written in the [`callPackage`](https://noogle.dev/f/pkgs/callPackage) style so you can just import them from the URL if you are feeling lazy.

## Auto-updates

These packages are automatically updated every night via GitHub Actions. Both the individual packages and the nixpkgs input are kept up to date with the latest upstream releases.

## Binary Cache

Pre-built binaries are available via [Cachix](https://cachix.org/). To use them, either run (see the [Cachix docs](https://docs.cachix.org/getting-started#using-binaries-with-nix) for more details):

```bash
cachix use giopkgs
```

Or add the cache to your Nix configuration:

```nix
{
  nix.settings = {
    substituters = [ "https://giopkgs.cachix.org" ];
    trusted-public-keys = [ "giopkgs.cachix.org-1:8oiYAit71TVQVQgzOWkbwsJZwvf89Yymi5Sx+BaEdEs=" ];
  };
}
```
