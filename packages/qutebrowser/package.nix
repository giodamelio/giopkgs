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
    version = "3.7.0-unstable-2026-11-16";

    src = pkgs.fetchFromGitHub {
      owner = "giodamelio";
      repo = "qutebrowser";
      rev = "bb9159220b42b55f4aedc87083b035122aa72709";
      hash = "sha256-o7Y2O6YrdJWiQlwu8FfX2qXZ65C4CqBNv2JrbJrqaPY=";
    };

    meta =
      oldAttrs.meta
      // {
        description = "qutebrowser from giodamelio's fork";
      };
  })
