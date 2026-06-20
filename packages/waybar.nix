{pkgs, ...}:
pkgs.waybar.overrideAttrs (oldAttrs: {
  patches =
    (oldAttrs.patches or [])
    ++ [
      # Adds cpu_graph module with line, gauge, and stacked bar graph types
      # Pinned to PR #4588 head commit (compare against base) so the patch
      # content is immutable and the hash won't drift as the PR is updated.
      (pkgs.fetchurl {
        url = "https://github.com/Alexays/Waybar/compare/202ae4bd5f2d8865704761211b3004d2fcd2d7d8...7d965a874f736854516f18320787ede9c6c47ef4.patch";
        hash = "sha256-FE14Eo3LVbY6RQQ7oHZi/oNYZ8bjyGmo03pntpys8B8=";
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
      description = "Waybar with PR #4588 (additional features/fixes)";
    };
})
