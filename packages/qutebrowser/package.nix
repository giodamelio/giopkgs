{pkgs, ...}: let
  # The fork depends on frizbee, which nixpkgs does not ship. Built from the
  # sdist rather than the prebuilt wheel so aarch64 is covered too.
  frizbee = pkgs.python3Packages.buildPythonPackage rec {
    pname = "frizbee";
    version = "0.13.0";
    pyproject = true;

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-NCMn3b+hbr4w2+zdZaw7Bd2WGulR/ALwu0rYSpQc81Y=";
    };

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-ds+T2FEIwTo5khCe39L7JiHfi/oJR48tETsnUtx1A88=";
    };

    nativeBuildInputs = with pkgs.rustPlatform; [cargoSetupHook maturinBuildHook];

    pythonImportsCheck = ["frizbee"];
  };
in
  (pkgs.qutebrowser.overridePythonAttrs (oldAttrs: {
    dependencies = oldAttrs.dependencies ++ [frizbee];
  })).overrideAttrs (oldAttrs: {
    version = "3.7.0-unstable-2026-11-12";

    src = pkgs.fetchFromGitHub {
      owner = "giodamelio";
      repo = "qutebrowser";
      rev = "c3c7b264d621551cb03903f904376a829e3c99c6";
      hash = "sha256-N2ZB4PskEu+RhJqG7kyNIR2qAEX4A4b1udTF2MaSxgI=";
    };

    meta =
      oldAttrs.meta
      // {
        description = "qutebrowser from giodamelio's fork";
      };
  })
