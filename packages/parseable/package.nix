{
  parseable,
  fetchFromGitHub,
  fetchzip,
  rustPlatform,
  ...
}: let
  version = "3.2.5";

  src = fetchFromGitHub {
    owner = "parseablehq";
    repo = "parseable";
    tag = "v${version}";
    hash = "sha256-r21LKGFoYc2IozOJDFKUYFLjjLnXUdHuO5QflD8ZE9E=";
  };
in
  parseable.overrideAttrs (oldAttrs: {
    inherit version src;

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-qUh+2IKk+utWNTU/pCUCwlmsNVPaUxra7JlNL2Brnq4=";
    };

    env =
      (oldAttrs.env or {})
      // {
        LOCAL_ASSETS_PATH = fetchzip {
          url = "https://parseableprismbuild.blob.core.windows.net/parseable-prism-build/v${version}/build.zip";
          hash = "sha256-Ckxy80wpkW31ba3sXzmz6y00rxmhCFDWvwKSADtsC/E=";
        };
      };

    patches = (oldAttrs.patches or []) ++ [./env-file-secrets.patch];

    meta =
      oldAttrs.meta
      // {
        description = "${oldAttrs.meta.description}, with _FILE env var secret indirection";
      };
  })
