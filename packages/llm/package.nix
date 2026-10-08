# llm and its plugins, resolved by uv rather than taken from nixpkgs, whose
# llm, llm-anthropic and anthropic versions drift out of step with each other.
#
# To update, run `uv lock --upgrade` in this directory and rebuild.
{
  lib,
  python3,
  callPackage,
  runCommand,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}: let
  workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

  pythonSet =
    (callPackage pyproject-nix.build.packages {python = python3;}).overrideScope
    (lib.composeManyExtensions [
      pyproject-build-systems.overlays.default
      (workspace.mkPyprojectOverlay {sourcePreference = "wheel";})
    ]);

  venv = pythonSet.mkVirtualEnv "llm-env" workspace.deps.default;

  inherit (lib.findFirst (p: p.name == "llm") (throw "llm missing from uv.lock") (lib.importTOML ./uv.lock).package) version;
in
  # Only bin/llm, so the venv's python and pip do not shadow another Python on PATH.
  runCommand "llm-${version}" {
    inherit version;
    passthru = {inherit venv;};
    meta = {
      description = "Access large language models from the command-line, with a fixed set of plugins";
      homepage = "https://github.com/simonw/llm";
      license = lib.licenses.asl20;
      maintainers = [];
      mainProgram = "llm";
    };
  } ''
    mkdir -p $out/bin
    ln -s ${venv}/bin/llm $out/bin/llm
  ''
