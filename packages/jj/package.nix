{
  jujutsu,
  fetchFromGitHub,
  fetchpatch,
  rustPlatform,
  ...
}: let
  version = "0.46.0-unstable-2026-10-10";
  rev = "987c084b8f3ff28e8246d8b38c55c323c85611d5";

  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    inherit rev;
    hash = "sha256-J0icVVxu4z8rDrDMAqRbkspLeoyCOp/eOA/yUVd4ZV8=";
  };
in
  jujutsu.overrideAttrs (old: {
    inherit version src;

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-b095mkhlS4Cqjd4vheOtnhLPxIx0EGSWw/nte6N/Wss=";
    };

    patches =
      (old.patches or [])
      ++ [
        # avamsi/jj: cli: aliases: support multi-word alias names.
        # Its parent is the pinned rev above, so it applies exactly.
        # REMIND-ME-TO: Drop this patch, jj ships multi-word aliases issue_closed=github:jj-vcs/jj#6611
        (fetchpatch {
          url = "https://github.com/avamsi/jj/commit/d783e1796cb1e5562014ce384e622e0c9a1e8c06.patch";
          hash = "sha256-IBeaqJvcT2VQVxTS9NOfaiiFOWwb8eAlRfGtkvV6nsk=";
        })
      ];

    # versionCheckHook greps `jj --version` for the derivation version, and the
    # binary only ever reports the Cargo version, never the -unstable- suffix.
    doInstallCheck = false;

    meta =
      old.meta
      // {
        description = "${old.meta.description}, from main with multi-word alias names";
        changelog = "https://github.com/jj-vcs/jj/blob/${rev}/CHANGELOG.md";
      };
  })
