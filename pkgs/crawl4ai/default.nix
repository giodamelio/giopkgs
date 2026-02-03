{ lib
, python3
, fetchFromGitHub
, playwright-driver
}:

python3.pkgs.buildPythonPackage rec {
  pname = "crawl4ai";
  version = "0.8.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "unclecode";
    repo = "crawl4ai";
    rev = "v${version}";
    hash = "sha256-P+bejaH3SVScNECajjozU3+o3dh8V/8V/N83yMPX2sU=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  postPatch = ''
    # Remove directory creation from setup.py that assumes writable HOME
    # Delete lines from "# Create the .crawl4ai folder" to "for folder in content_folders:"
    sed -i '/# Create the .crawl4ai folder/,/^    (crawl4ai_folder \/ folder).mkdir(exist_ok=True)/d' setup.py
  '';

  dependencies = with python3.pkgs; [
    aiofiles
    aiohttp
    aiosqlite
    anyio
    lxml
    litellm
    numpy
    pillow
    playwright
    # patchright  # Not available in nixpkgs, but playwright should work
    python-dotenv
    requests
    beautifulsoup4
    # tf-playwright-stealth  # Not available in nixpkgs
    xxhash
    rank-bm25
    snowballstemmer
    pydantic
    pyopenssl
    psutil
    pyyaml
    nltk
    rich
    cssselect
    httpx
    fake-useragent
    click
    chardet
    brotli
    humanize
    lark
    # alphashape  # Not available in nixpkgs
    shapely
  ];

  # Optional dependencies can be added via overrides
  passthru.optional-dependencies = with python3.pkgs; {
    pdf = [ pypdf ];
    torch = [ pytorch nltk scikit-learn ];
    transformer = [ transformers tokenizers sentence-transformers ];
    cosine = [ pytorch transformers nltk sentence-transformers ];
    sync = [ selenium ];
  };

  # Skip import check as it tries to create directories in HOME
  # pythonImportsCheck = [ "crawl4ai" ];

  # Don't check runtime dependencies strictly as some packages have version mismatches
  # or are not available in nixpkgs (patchright, tf-playwright-stealth, alphashape)
  pythonRemoveDeps = [
    "patchright"  # Not in nixpkgs, playwright is sufficient
    "tf-playwright-stealth"  # Not in nixpkgs
    "alphashape"  # Not in nixpkgs
  ];

  pythonRelaxDeps = [
    "lxml"
    "snowballstemmer"
    "pyOpenSSL"
  ];

  # Set environment variable to point to Nix-provided Playwright browsers
  makeWrapperArgs = [
    "--set PLAYWRIGHT_BROWSERS_PATH ${playwright-driver.browsers}"
    "--set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD 1"
  ];

  # Tests require network access and browser setup
  doCheck = false;

  meta = with lib; {
    description = "Open-source LLM Friendly Web Crawler & scraper";
    homepage = "https://github.com/unclecode/crawl4ai";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    mainProgram = "crwl";
  };
}
