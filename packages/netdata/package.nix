{
  callPackage,
  netdata,
  # nixosTests,
  ...
}: let
  patchedNetdata = netdata.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./netdata-file-secrets.patch];
  });
in
  patchedNetdata.overrideAttrs (old: {
    passthru =
      (old.passthru or {})
      // {
        updatePolicy = "skip";
        tests = {
          # Upstream test disabled - fails with 404 on curl http://127.0.0.1:19999
          # even with unpatched netdata. Likely a flaky/broken upstream test.
          # To re-enable:
          # netdata = nixosTests.netdata.extendNixOS {
          #   module = { services.netdata.package = lib.mkForce patchedNetdata; };
          # };
          file-secrets = callPackage ./netdata-file-secrets-test.nix {
            netdata = patchedNetdata;
          };
        };
      };
  })
