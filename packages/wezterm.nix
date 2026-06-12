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

      # Fix Wayland clipboard not working between multiple windows (#6685)
      # REMIND-ME-TO: Remove this patch pr_released=github:wezterm/wezterm#7034
      (fetchpatch {
        url = "https://github.com/wezterm/wezterm/commit/3f062e0aa1924dc5666a57b0e7d065cc26a3b29b.patch";
        hash = "sha256-wEpl9ODe6evUQCem7BgoavENl+iQtRKHVtmIS5UelNI=";
      })

      # Fix kitty spec for ESC key (needing to hit Esc twice)
      # REMIND-ME-TO: Remove this patch pr_released=github:wezterm/wezterm#7787
      (fetchpatch {
        url = "https://patch-diff.githubusercontent.com/raw/wezterm/wezterm/pull/7787.patch";
        hash = "sha256-hYhb5foZ3rqGEGNZXmToaNGgP1IOHcih4S5btrJionk=";
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
      description = "Wezterm with PR #7510, PR #7034 and PR #7787";
    };
})
