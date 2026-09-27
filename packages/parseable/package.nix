{
  parseable,
  fetchFromGitHub,
  fetchzip,
  rustPlatform,
  ...
}: let
  version = "3.2.2";

  src = fetchFromGitHub {
    owner = "parseablehq";
    repo = "parseable";
    tag = "v${version}";
    hash = "sha256-3EIRUWaFvlBYY80/lMoRlNfxLwRxARQAC7N1iEpXZ84=";
  };
in
  parseable.overrideAttrs (oldAttrs: {
    inherit version src;

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-wKO8kokM+kXQ98PIhnep0/twkoUIwX+hAVsmZfdY4D4=";
    };

    env =
      (oldAttrs.env or {})
      // {
        LOCAL_ASSETS_PATH = fetchzip {
          url = "https://parseableprismbuild.blob.core.windows.net/parseable-prism-build/v${version}/build.zip";
          hash = "sha256-CXMPeY/AzL/O1vx8H25Q6eXRgbKbhvmJLAC+7zmlqnQ=";
        };
      };

    patches = (oldAttrs.patches or []) ++ [./env-file-secrets.patch];

    meta =
      oldAttrs.meta
      // {
        description = "${oldAttrs.meta.description}, with _FILE env var secret indirection";
      };
  })
