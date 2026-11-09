{pkgs, ...}:
# vminsert, vmselect and vmstorage are only `main` packages on the -cluster
# tag; nixpkgs builds the single-node tag, where they are libraries and yield
# no binaries. The version is pinned here rather than taken from nixpkgs so a
# nixpkgs bump cannot cause a hash mismatch.
pkgs.victoriametrics.overrideAttrs (finalAttrs: old: {
  pname = "VictoriaMetrics-cluster";
  version = "1.156.0-cluster";

  src = pkgs.fetchFromGitHub {
    owner = "VictoriaMetrics";
    repo = "VictoriaMetrics";
    tag = "v${finalAttrs.version}";
    hash = "sha256-uZYZTScJLvLvuMBYHmPCjqzY39BjbXtr0WWR0bwaxN0=";
  };

  subPackages = [
    "app/vminsert"
    "app/vmselect"
    "app/vmstorage"
  ];

  passthru =
    builtins.removeAttrs old.passthru ["updateScript"]
    // {
      # nixosTests.victoriametrics covers the single-node server, not these.
      tests = {};
    };

  meta =
    old.meta
    // {
      description = "VictoriaMetrics cluster components: vminsert, vmselect and vmstorage";
      changelog = "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/tag/v${finalAttrs.version}";
      mainProgram = "vmstorage";
    };
})
