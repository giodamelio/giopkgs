{
  description = "Misc packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ] (system: function nixpkgs.legacyPackages.${system});

    packagesFor = pkgs: {
      tidewave-cli = pkgs.callPackage ./packages/tidewave-cli {};
      mcporter = pkgs.callPackage ./packages/mcporter {};
      mcptools = pkgs.callPackage ./packages/mcptools.nix {};
      crawl4ai = pkgs.callPackage ./pkgs/crawl4ai {};
    };
  in {
    packages = forAllSystems packagesFor;

    overlays.default = final: prev: packagesFor final;

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nix-init # Help scaffold new package automatically
          nurl # Fetch a URL and give a Nix style fetch statement with the correct hash
          nix-update # Easily Auto Update version/src hashs for derivations
          crate2nix # Help building Rust packages (adding this to handle building a single crate from a workspace)
        ];
      };
    });
  };
}
