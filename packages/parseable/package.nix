{
  parseable,
  fetchFromGitHub,
  fetchzip,
  rustPlatform,
  ...
}: let
  version = "3.2.6";

  src = fetchFromGitHub {
    owner = "parseablehq";
    repo = "parseable";
    tag = "v${version}";
    hash = "sha256-1qNToYj15BOnQHaRtwWeTKAAgYYbQnjg4syQXot9buc=";
  };
in
  parseable.overrideAttrs (oldAttrs: {
    inherit version src;

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-sseuT4uCqndav9n8nYjBoTym7ByE5cLC0tmjJjJuT6I=";
    };

    env =
      (oldAttrs.env or {})
      // {
        LOCAL_ASSETS_PATH = fetchzip {
          url = "https://parseableprismbuild.blob.core.windows.net/parseable-prism-build/v${version}/build.zip";
          hash = "sha256-UdV1bPfJMIErEQs9Njx+o+5EqVQN/7CCrmDSiI2gWzA=";
        };
      };

    patches = (oldAttrs.patches or []) ++ [./env-file-secrets.patch];

    meta =
      oldAttrs.meta
      // {
        description = "${oldAttrs.meta.description}, with _FILE env var secret indirection";
      };
  })
