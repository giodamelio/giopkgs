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
  # borg 2.0.0b21 hard-fails at runtime on msgpack > 1.1.2 (guard in
  # borg/helpers/msgpack.py), so pin it instead of relaxing the constraint.
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
    };
  };

  borghash = python.pkgs.buildPythonPackage rec {
    pname = "borghash";
    version = "0.1.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "borgbackup";
      repo = "borghash";
      tag = version;
      hash = "sha256-aJplDFMHoDzTOD/8Z9OGhWDvKapXJ5kiho/3b4aCwa4=";
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
    version = "0.4.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "borgbackup";
      repo = "borgstore";
      tag = version;
      hash = "sha256-zQdo/bJD3KI7/qgMLfcaWY+PP4vbBE/hlGS+y+3DFzI=";
    };

    env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

    build-system = with python.pkgs; [
      setuptools
      setuptools-scm
    ];

    dependencies = with python.pkgs; [
      paramiko
      requests
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
    version = "2.0.0b21";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "borgbackup";
      repo = "borg";
      tag = finalAttrs.version;
      hash = "sha256-u9hXzo4OyOf6iixQhm3NEzVDb+4irkaLHH2PjnmfmM8=";
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
        argon2-cffi
        shtab
        jsonargparse
        pyyaml
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

    postInstall = ''
      installShellCompletion --cmd borg \
        --fish scripts/shell_completions/fish/borg.fish
    '';

    doCheck = false;

    nativeInstallCheckInputs = [
      versionCheckHook
    ];
    versionCheckProgramArg = "--version";
    doInstallCheck = true;

    passthru.updateScript = ./update.sh;

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
