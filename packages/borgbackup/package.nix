{
  lib,
  stdenv,
  acl,
  fetchFromGitHub,
  libb2,
  lz4,
  openssh,
  openssl,
  python3,
  xxhash,
  zstd,
  installShellFiles,
  versionCheckHook,
}: let
  # borg hard-fails at runtime on msgpack outside its supported range (guard in
  # borg/helpers/msgpack.py), so pin it instead of relaxing the constraint.
  # 2.0.0b22 raised its own ceiling to 1.2.1, so this pin may be droppable once
  # nixpkgs' msgpack lands inside that range.
  python = python3.override {
    packageOverrides = _final: prev: {
      msgpack = prev.msgpack.overridePythonAttrs (_old: rec {
        version = "1.1.2";
        src = fetchFromGitHub {
          owner = "msgpack";
          repo = "msgpack-python";
          tag = "v${version}";
          hash = "sha256-9iFTQPAM6AAogcRUoCw5/bECNiGUwmAarEiwMJ+rqbk=";
        };
      });
      # 2.0.0b24 requires shtab >= 1.11.0 for correct zsh and fish completions.
      shtab = prev.shtab.overridePythonAttrs (old: rec {
        version = "1.12.1";
        src = fetchFromGitHub {
          owner = "tqdm";
          repo = "shtab";
          tag = "v${version}";
          hash = "sha256-M3otTelW+tkxnB5WRQGQZhwucA9CUif0ahPl5WhgUOw=";
        };
        nativeCheckInputs = old.nativeCheckInputs ++ [prev.click];
      });
    };
  };

  borghash = python.pkgs.buildPythonPackage rec {
    pname = "borghash";
    version = "0.2.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "borgbackup";
      repo = "borghash";
      tag = version;
      hash = "sha256-IBykQrB3WG4Vq3SbEfK8QAUDxXglwbnRncnfLRhKWkA=";
    };

    env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

    build-system = with python.pkgs; [
      setuptools
      setuptools-scm
      cython
      wheel
    ];

    pythonImportsCheck = ["borghash"];

    meta = {
      description = "Hashtables implemented in Cython, used by borgbackup 2.0";
      homepage = "https://github.com/borgbackup/borghash";
      license = lib.licenses.bsd3;
      maintainers = [];
    };
  };

  borgstore = python.pkgs.buildPythonPackage rec {
    pname = "borgstore";
    version = "0.7.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "borgbackup";
      repo = "borgstore";
      tag = version;
      hash = "sha256-14iWLlhKmj6oOftoK0Ma1FProN8UmLzjzPV+7kiy8Sw=";
    };

    env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

    build-system = with python.pkgs; [
      setuptools
      setuptools-scm
    ];

    dependencies = with python.pkgs; [
      paramiko
      requests
      blake3
    ];

    pythonImportsCheck = ["borgstore"];

    meta = {
      description = "Key/value store for borgbackup 2.0";
      homepage = "https://github.com/borgbackup/borgstore";
      license = lib.licenses.bsd3;
      maintainers = [];
    };
  };
in
  python.pkgs.buildPythonApplication (finalAttrs: {
    pname = "borgbackup";
    version = "2.0.0b25";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "borgbackup";
      repo = "borg";
      tag = finalAttrs.version;
      hash = "sha256-H1ePbqWsULvZvHXQiSBSxxkomsAOMuIUJUBhGbFzO8s=";
    };

    env.SETUPTOOLS_SCM_PRETEND_VERSION = finalAttrs.version;

    build-system = with python.pkgs; [
      cython
      setuptools
      setuptools-scm
      pkgconfig
      wheel
    ];

    nativeBuildInputs = [
      installShellFiles
    ];

    buildInputs =
      [
        libb2
        lz4
        xxhash
        zstd
        openssl
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        acl
      ];

    dependencies = with python.pkgs;
      [
        borghash
        borgstore
        msgpack
        packaging
        platformdirs
        shtab
        jsonargparse
        pyyaml
        blake3 # new runtime dependency in 2.0.0b22
      ]
      ++ [python.pkgs.xxhash]
      ++ lib.optionals (pythonOlder "3.14") [
        backports-zstd
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        pyfuse3
      ];

    makeWrapperArgs = [
      ''--prefix PATH ':' "${openssh}/bin"''
    ];

    postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      installShellCompletion --cmd borg \
        --fish <(HOME=$TMPDIR $out/bin/borg completion fish)
    '';

    doCheck = false;

    nativeInstallCheckInputs = [
      versionCheckHook
    ];
    versionCheckProgramArg = "--version";
    doInstallCheck = true;

    meta = {
      changelog = "https://github.com/borgbackup/borg/blob/${finalAttrs.src.rev}/docs/changes.rst";
      description = "Deduplicating archiver with compression and encryption (2.0 beta)";
      homepage = "https://www.borgbackup.org";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.unix;
      mainProgram = "borg";
      maintainers = [];
    };
  })
