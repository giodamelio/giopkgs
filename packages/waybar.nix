{
  pkgs,
  lib,
  ...
}:
pkgs.waybar.overrideAttrs (oldAttrs: {
  patches =
    (oldAttrs.patches or [])
    ++ [
      # Adds cpu_graph module with line, gauge, and stacked bar graph types
      (pkgs.fetchurl {
        url = "https://patch-diff.githubusercontent.com/raw/Alexays/Waybar/pull/4588.patch";
        hash = "sha256-t+72Wam1GsgG3Ra2ZVDIInV/g0PL2ddpvdxyXnn6//8=";
      })
    ];

  meta =
    oldAttrs.meta
    // {
      description = "Waybar with PR #4588 (additional features/fixes)";
    };
})
