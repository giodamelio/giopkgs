{pkgs, ...}:
(pkgs.victorialogs.override {withVlAgent = true;}).overrideAttrs (old: {
  passthru =
    old.passthru
    // {
      updatePolicy = "skip";
      # nixosTests.victorialogs does not exercise vlagent, and its
      # recurseForDerivations marker is not a derivation for `checks`.
      tests = {};
    };
})
