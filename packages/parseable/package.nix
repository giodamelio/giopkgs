{
  parseable,
  fetchFromGitHub,
  fetchzip,
  rustPlatform,
  ...
}: let
  version = "3.2.3";

  src = fetchFromGitHub {
    owner = "parseablehq";
    repo = "parseable";
    tag = "v${version}";
    hash = "sha256-8ku0ZJjznOiF9FGCJ5pfGEuZ0rWcWXkOmUrC1IrGgAo=";
  };
in
  parseable.overrideAttrs (oldAttrs: {
    inherit version src;

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-cz9krJf8EGJj1vW35dNpx01Dd0UFVSInb4/FD7Ab9MI=";
    };

    env =
      (oldAttrs.env or {})
      // {
        LOCAL_ASSETS_PATH = fetchzip {
          url = "https://parseableprismbuild.blob.core.windows.net/parseable-prism-build/v${version}/build.zip";
          hash = "sha256-PISGAytYLqJ3S4I9XjQNh4WWGJ+mz9TYpq9J/H/WhYI=";
        };
      };

    patches = (oldAttrs.patches or []) ++ [./env-file-secrets.patch];

    meta =
      oldAttrs.meta
      // {
        description = "${oldAttrs.meta.description}, with _FILE env var secret indirection";
      };
  })
