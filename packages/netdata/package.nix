{
  lib,
  callPackage,
  netdata,
  ...
}:
netdata.overrideAttrs (old: rec {
  patches = (old.patches or []) ++ [./netdata-file-secrets.patch];

  passthru = lib.recursiveUpdate (old.passthru or {}) {
    tests.file-secrets = callPackage ./netdata-file-secrets-test.nix {
      netdata = netdata.overrideAttrs {inherit patches;};
    };
  };
})
