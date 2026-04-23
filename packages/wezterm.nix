{
  pkgs,
  fetchpatch,
  ...
}:
pkgs.wezterm.overrideAttrs (oldAttrs: {
  patches =
    (oldAttrs.patches or [])
    ++ [
      # This PR adds a new pane-focus-changed I want
      # REMIND-ME-TO: Remove this patch pr_released=github:wezterm/wezterm#7510
      (fetchpatch {
        url = "https://patch-diff.githubusercontent.com/raw/wezterm/wezterm/pull/7510.patch";
        hash = "sha256-iIwkg1Tf/tcZQlCqsPeu32uu6fKV0ye9JaKlU6skF00=";
      })
    ];

  passthru =
    (oldAttrs.passthru or {})
    // {
      updateScript = ./../scripts/skip-update.sh;
    };

  meta =
    oldAttrs.meta
    // {
      description = "Wezterm with PR #7510";
    };
})
