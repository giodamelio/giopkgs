{
  description = "Misc packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ] (system:
        function (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }));

    # Collect passthru.tests from all packages into checks
    collectTests = packages:
      nixpkgs.lib.foldlAttrs (
        acc: name: pkg:
          acc
          // (
            if pkg ? passthru.tests
            then
              nixpkgs.lib.mapAttrs' (
                testName: test:
                  nixpkgs.lib.nameValuePair "${name}-${testName}" test
              )
              pkg.passthru.tests
            else {}
          )
      ) {}
      packages;
  in {
    packages = forAllSystems (
      pkgs:
        nixpkgs.lib.filesystem.packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage;
          directory = ./packages;
        }
    );

    checks = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"] (system:
      collectTests self.packages.${system}
    );

    overlays.default = final: prev:
      nixpkgs.lib.filesystem.packagesFromDirectoryRecursive {
        callPackage = final.callPackage;
        directory = ./packages;
      };

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nix-init # Help scaffold new package automatically
          nurl # Fetch a URL and give a Nix style fetch statement with the correct hash
          nix-update # Easily Auto Update version/src hashs for derivations
          crate2nix # Help building Rust packages (adding this to handle building a single crate from a workspace)
          prek # Git Hooks
          alejandra # Nix formatting
          shellcheck # Shell script linting
          statix # Nix linting
          deadnix # Find dead Nix code
        ];
        shellHook = ''
          prek install
        '';
      };
    });
  };
}
