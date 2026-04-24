{
  lib,
  python3,
  fetchFromGitHub,
  fetchPypi,
  fetchurl,
  chromium,
  autoPatchelfHook,
  stdenv,
  makeWrapper,
}: let
  python = python3.override {
    self = python;
    packageOverrides = _final: prev: {
      uuid7 = prev.buildPythonPackage rec {
        pname = "uuid7";
        version = "0.1.0";
        format = "setuptools";

        src = fetchPypi {
          inherit pname version;
          hash = "sha256-jFeqMu50VtPMaMlcRTC8VxZG3vrAGJXPxzVFRJiUpjw=";
        };

        doCheck = false;

        meta = {
          description = "UUID version 7, generating time-sorted UUIDs";
          homepage = "https://github.com/stevesimmons/uuid7";
          license = lib.licenses.mit;
        };
      };

      bubus = prev.buildPythonPackage rec {
        pname = "bubus";
        version = "1.5.6";
        pyproject = true;

        src = fetchPypi {
          inherit pname version;
          hash = "sha256-GlRW8KV26GYTp71m6BmJG2d3eDILbikQlOM5sNnfLg0=";
        };

        build-system = [prev.hatchling];

        dependencies = with prev; [
          aiofiles
          anyio
          portalocker
          pydantic
          typing-extensions
          _final.uuid7
        ];

        doCheck = false;

        meta = {
          description = "Advanced Pydantic-powered event bus with async support";
          homepage = "https://pypi.org/project/bubus/";
          license = lib.licenses.mit;
        };
      };

      cdp-use = prev.buildPythonPackage rec {
        pname = "cdp-use";
        version = "1.4.5";
        pyproject = true;

        src = fetchPypi {
          pname = "cdp_use";
          inherit version;
          hash = "sha256-DaOjLfRjNqA/9aIrxrxELNfS8tUKEY/UhW8p039tJqA=";
        };

        build-system = [prev.hatchling];

        dependencies = with prev; [
          httpx
          typing-extensions
          websockets
        ];

        doCheck = false;

        meta = {
          description = "Type-safe Python client for Chrome DevTools Protocol";
          homepage = "https://github.com/browser-use/cdp-use";
          license = lib.licenses.mit;
        };
      };

      browser-use-sdk = prev.buildPythonPackage rec {
        pname = "browser-use-sdk";
        version = "3.4.3";
        pyproject = true;

        src = fetchPypi {
          pname = "browser_use_sdk";
          inherit version;
          hash = "sha256-uuJpwqKPcuXO0bl/Hrx+lL/AGM6yzmO1qZg4RAyk4tE=";
        };

        build-system = [prev.hatchling];

        dependencies = with prev; [
          httpx
          pydantic
        ];

        doCheck = false;

        meta = {
          description = "Python SDK for the Browser Use cloud API";
          homepage = "https://pypi.org/project/browser-use-sdk/";
          license = lib.licenses.mit;
        };
      };
    };
  };

  profile-use = stdenv.mkDerivation rec {
    pname = "profile-use";
    version = "1.0.5";

    src = fetchurl {
      url = "https://github.com/browser-use/profile-use-releases/releases/download/v${version}/profile-use-linux-amd64";
      hash = "sha256-wo7vbMmdPnDVQ6aBzDE1UuPr7DPWtdJVJ717JukWOWU=";
    };

    nativeBuildInputs = [autoPatchelfHook];

    dontUnpack = true;

    installPhase = ''
      install -Dm755 $src $out/bin/profile-use
    '';

    meta = {
      description = "Browser profile sync tool for browser-use";
      homepage = "https://github.com/browser-use/profile-use-releases";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
    };
  };

  deps = with python.pkgs; [
    aiohttp
    anyio
    bubus
    click
    inquirerpy
    rich
    google-api-core
    httpx
    posthog
    psutil
    pydantic
    python-dotenv
    requests
    screeninfo
    typing-extensions
    uuid7
    google-genai
    openai
    anthropic
    groq
    ollama
    google-api-python-client
    google-auth
    google-auth-oauthlib
    mcp
    pypdf
    reportlab
    cdp-use
    pyotp
    pillow
    cloudpickle
    markdownify
    python-docx
    browser-use-sdk
  ];
in
  python.pkgs.buildPythonApplication rec {
    pname = "browser-use";
    version = "0.12.6";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "browser-use";
      repo = "browser-use";
      tag = "0.12.6";
      hash = "sha256-hX5pmOmmDN6KL+jqkV1b/hQ2tmauCnHZec00vQXnWyI=";
    };

    build-system = [python.pkgs.hatchling];

    nativeBuildInputs = [makeWrapper];

    pythonRelaxDeps = true;

    pythonRemoveDeps = [
      # macOS only
      "pyobjc"
    ];

    dependencies = deps;

    postPatch = ''
      # Patch profile-use to look for the binary on PATH instead of
      # only in ~/.browser-use/bin/
      substituteInPlace browser_use/skill_cli/profile_use.py \
        --replace-fail \
          "binary = get_bin_dir() / ('profile-use.exe' if sys.platform == 'win32' else 'profile-use')" \
          "binary = Path(shutil.which('profile-use') or (get_bin_dir() / 'profile-use'))"

      # Add Nix chromium path to browser discovery so the watchdog finds it
      # without needing /usr/bin or Playwright downloads
      substituteInPlace browser_use/browser/watchdogs/local_browser_watchdog.py \
        --replace-fail \
          "('chrome', '/usr/bin/google-chrome-stable')," \
          "('chromium', '${lib.getExe chromium}'), ('chrome', '/usr/bin/google-chrome-stable'),"

      # Disable chromium sandbox by default on NixOS. The SUID sandbox helper
      # at /run/wrappers/bin/__chromium-suid-sandbox may not be configured,
      # causing chromium to crash immediately after launch.
      substituteInPlace browser_use/browser/profile.py \
        --replace-fail \
          "default=not CONFIG.IN_DOCKER, description='Whether to enable Chromium sandboxing (recommended unless inside Docker).'" \
          "default=False, description='Whether to enable Chromium sandboxing (disabled on NixOS).'"
    '';

    # Set PYTHONPATH so the daemon subprocess (spawned via sys.executable)
    # can find browser_use and all dependencies. The Nix wrapper sets up
    # site-packages via site.addsitedir in the wrapper script, but that
    # only affects the main process — the daemon subprocess uses the raw
    # Python interpreter and needs PYTHONPATH inherited from the environment.
    postFixup = ''
      wrapProgram $out/bin/browser-use \
        --prefix PATH : ${lib.makeBinPath [chromium profile-use]} \
        --set PYTHONPATH "$out/${python.sitePackages}:${python.pkgs.makePythonPath deps}"
    '';

    doCheck = false;

    passthru = {
      inherit profile-use;
    };

    meta = {
      description = "Make websites accessible for AI agents";
      homepage = "https://github.com/browser-use/browser-use";
      license = lib.licenses.mit;
      maintainers = [];
      mainProgram = "browser-use";
    };
  }
