{
  jujutsu,
  fetchFromGitHub,
  fetchpatch,
  rustPlatform,
  ...
}: let
  version = "0.45.1-unstable-2026-09-20";
  rev = "aa8c087f7d2f32cdbbc41a7e3816e7a9f1cfc001";

  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    inherit rev;
    hash = "sha256-EmPAA7sEQSS/I2fUF9zfgI6ZgFpgrEjFxQciv9vLw5g=";
  };
in
  jujutsu.overrideAttrs (old: {
    inherit version src;

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-x3fffc8P15LwKkq3M2j3wA3YRxUYTCL69qfD6SkI/j0=";
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
