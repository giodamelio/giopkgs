{
  parseable,
  fetchFromGitHub,
  fetchzip,
  rustPlatform,
  ...
}: let
  version = "2.9.5";

  src = fetchFromGitHub {
    owner = "parseablehq";
    repo = "parseable";
    tag = "v${version}";
    hash = "sha256-BcUemor3Ae77WZCQK2RsRwoyLM4DKjs6EMgvMMMBR3o=";
  };
in
  parseable.overrideAttrs (oldAttrs: {
    inherit version src;

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-P8nXjV+6TcghstG78YQinel06a9mgTnk51gtUzKCSaU=";
    };

    env =
      (oldAttrs.env or {})
      // {
        LOCAL_ASSETS_PATH = fetchzip {
          url = "https://parseable-prism-build.s3.us-east-2.amazonaws.com/v${version}/build.zip";
          hash = "sha256-CQJJwR2y1DQ4DXKFhsKgxiI1AhXp9ipkxGNlKIQ3evQ=";
        };
      };

    patches = (oldAttrs.patches or []) ++ [./env-file-secrets.patch];

    meta =
      oldAttrs.meta
      // {
        description = "${oldAttrs.meta.description}, with _FILE env var secret indirection";
      };
  })
