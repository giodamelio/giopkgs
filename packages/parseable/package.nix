{
  parseable,
  fetchFromGitHub,
  fetchzip,
  rustPlatform,
  ...
}: let
  version = "3.2.7";

  src = fetchFromGitHub {
    owner = "parseablehq";
    repo = "parseable";
    tag = "v${version}";
    hash = "sha256-6Hkpz4bReGjBJjRw3Ni/JGKHjumFw1zf+rQDPNqGxHY=";
  };
in
  parseable.overrideAttrs (oldAttrs: {
    inherit version src;

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-PmKd0SOKit6se/IVVk0Uh9QLyWyG+lWS9tUE+FyIYCI=";
    };

    env =
      (oldAttrs.env or {})
      // {
        LOCAL_ASSETS_PATH = fetchzip {
          url = "https://parseableprismbuild.blob.core.windows.net/parseable-prism-build/v${version}/build.zip";
          hash = "sha256-LvsGPMKUSJV9omBOMMDcd1BmWqffAOLKfo3WHI/fKvE=";
        };
      };

    patches = (oldAttrs.patches or []) ++ [./env-file-secrets.patch];

    meta =
      oldAttrs.meta
      // {
        description = "${oldAttrs.meta.description}, with _FILE env var secret indirection";
      };
  })
