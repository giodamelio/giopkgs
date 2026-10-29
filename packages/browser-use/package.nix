{
  lib,
  python3,
  fetchFromGitHub,
  fetchPypi,
  fetchurl,
  chromium,
  autoPatchelfHook,
  stdenv,
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
        version = "3.12.1";
        pyproject = true;

        src = fetchPypi {
          pname = "browser_use_sdk";
          inherit version;
          hash = "sha256-lMKocOXsUHKyFmGm9P7L8QbavhxA6HkMZwIIHFLznS8=";
        };

        build-system = [prev.hatchling];

        # Upstream wants idna>=3.19; nixpkgs is a patch release behind.
        pythonRelaxDeps = ["idna"];

        dependencies = with prev; [
          httpx
          idna
          pydantic
        ];

        doCheck = false;

        meta = {
          description = "Python SDK for the Browser Use cloud API";
          homepage = "https://pypi.org/project/browser-use-sdk/";
          license = lib.licenses.mit;
        };
      };

      fetch-use = prev.buildPythonPackage rec {
        pname = "fetch-use";
        version = "0.4.0";
        pyproject = true;

        src = fetchPypi {
          pname = "fetch_use";
          inherit version;
          hash = "sha256-lRGYfUkH7G2sUB4h1mlG0QCY9mtdIbwqukGJzYG6GJo=";
        };

        build-system = [prev.hatchling];

        doCheck = false;

        meta = {
          description = "Python client for the Browser Use Fetch HTTP service";
          homepage = "https://github.com/browser-use/fetch-use";
          license = lib.licenses.mit;
        };
      };

      browser-harness = prev.buildPythonPackage rec {
        pname = "browser-harness";
        version = "0.1.13";
        pyproject = true;

        src = fetchPypi {
          pname = "browser_harness";
          inherit version;
          hash = "sha256-KE3FR6BCwwn+r9mp9KdLKoZRt5Y+o6xssvLWSIn2qPM=";
        };

        # The build backend is pinned to an exact setuptools release.
        postPatch = ''
          substituteInPlace pyproject.toml \
            --replace-fail '"setuptools==84.0.0"' '"setuptools"'
        '';

        build-system = [prev.setuptools];

        pythonRelaxDeps = true;

        dependencies = with prev; [
          _final.cdp-use
          _final.fetch-use
          pillow
          websockets
        ];

        doCheck = false;

        pythonImportsCheck = ["browser_harness"];

        meta = {
          description = "Thin harness for driving a real browser from an agent over CDP";
          homepage = "https://github.com/browser-use/browser-harness";
          license = lib.licenses.mit;
        };
      };

      # nixpkgs marks posthog broken once mcp reaches 2, but mcp is only one of
      # its test inputs; the library itself never imports it.
      posthog = prev.posthog.overridePythonAttrs (old: {
        doCheck = false;
        meta = old.meta // {broken = false;};
      });
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
    pydantic-settings
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
    browser-harness
  ];
in
  python.pkgs.buildPythonApplication rec {
    pname = "browser-use";
    version = "0.13.14";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "browser-use";
      repo = "browser-use";
      tag = version;
      hash = "sha256-HrAxu6t//HIQmoeCkuwBZHUWWZayWD1SLcrSl6Od0Ps=";
    };

    build-system = [python.pkgs.hatchling];

    pythonRelaxDeps = true;

    pythonRemoveDeps = [
      # macOS only
      "pyobjc"
    ];

    dependencies = deps;

    postPatch = ''
      # The build backend is pinned to an exact hatchling release.
      substituteInPlace pyproject.toml \
        --replace-fail '"hatchling==1.32.0"' '"hatchling"'

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

    # Set PYTHONPATH so the browser-harness daemon (spawned via sys.executable)
    # can find browser_use and all dependencies. The Nix wrapper sets up
    # site-packages via site.addsitedir in the wrapper script, but that
    # only affects the main process — the daemon subprocess uses the raw
    # Python interpreter and needs PYTHONPATH inherited from the environment.
    # browser-harness also runs profile-use and the browser from PATH. These
    # apply to every entry point, not just bin/browser-use.
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      (lib.makeBinPath [chromium profile-use])
      "--set"
      "PYTHONPATH"
      "${placeholder "out"}/${python.sitePackages}:${python.pkgs.makePythonPath deps}"
    ];

    doCheck = false;

    pythonImportsCheck = ["browser_use" "browser_use.cli" "browser_harness"];

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
