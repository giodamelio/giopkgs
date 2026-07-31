# Packages kept for reference but no longer built, checked or updated by CI.
#
# Archiving is only a CI-cost decision. Nothing is removed from the flake:
#
#   nix build .#<name>     works exactly as before
#   nix flake check        still covers archived packages locally
#   nix flake check --no-build   still evaluates them, so they cannot rot into
#                                syntax errors unnoticed
#
# Only the CI build matrix, the nightly update matrix, and the checks CI builds
# skip them. Trigger the Build Packages workflow manually with scope "all" or
# "archived-only" to build them on demand.
#
# The trade-off: an archived package stops being cached and will drift out of
# buildability over time, so reviving one may mean a repair job.
#
# Values are the reason for archiving — this file doubles as the record of what
# was packaged and why it was shelved.
{
  # solidtime = "stopped self-hosting it, 2026-05";
}
