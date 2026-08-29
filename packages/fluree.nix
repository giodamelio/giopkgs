{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  perl,
  installShellFiles,
}: let
  # Shared with packages/fluree-docs.nix through passthru, so the release-profile
  # doc pass here and the dev-profile one there cannot drift apart.
  docFlags = ["--workspace" "--no-deps" "--document-private-items"];

  # Expects $docSrc (a rustdoc output dir) and $docOut (where to install it).
  installDocs = ''
    mkdir -p "$docOut"
    cp -r "$docSrc"/. "$docOut"/

    # cargo leaves its build lock inside the doc tree.
    rm -f "$docOut/.lock"

    # rustdoc emits one index.html per crate and no workspace landing page, so
    # without this the output has no entry point.
    {
      echo '<!DOCTYPE html><meta charset="utf-8">'
      echo "<title>Fluree DB $version workspace crates</title>"
      echo "<h1>Fluree DB $version workspace crates</h1>"
      echo '<ul>'
      for index in "$docOut"/*/index.html; do
        crate="$(basename "$(dirname "$index")")"
        echo "<li><a href=\"$crate/index.html\">$crate</a></li>"
      done
      echo '</ul>'
    } > "$docOut/index.html"
  '';
in
  rustPlatform.buildRustPackage rec {
    pname = "fluree";
    version = "4.1.6";

    src = fetchFromGitHub {
      owner = "fluree";
      repo = "db";
      tag = "v${version}";
      hash = "sha256-BMYYEo1kIpn37AWYqDIO3syv59nr/HaFpzSGsrOUBpY=";
    };

    cargoHash = "sha256-LCK+DAJAiFwRZ4P0JQf86tSTkxek36tcv+hsV7uUjC8=";

    # The workspace holds 44 crates; only fluree-db-cli produces a shipped
    # binary. Its default `server` feature links fluree-db-server in as a
    # library, so `fluree server run` is the HTTP server — the standalone
    # fluree-server binary is marked `dist = false` upstream.
    cargoBuildFlags = ["--package" "fluree-db-cli"];

    # aws-lc-sys, reached through rustls.
    nativeBuildInputs = [cmake perl installShellFiles];

    doCheck = false;

    outputs = ["out" "doc"];

    passthru = {inherit docFlags installDocs;};

    # None of these crates are published, so rustdoc is the only way to browse
    # them. cargoBuildHook builds with an explicit --target; passing the same one
    # here keeps rustdoc on the release artifacts it just produced instead of
    # recompiling the workspace for the host default.
    postBuild = ''
      cargo doc --offline --release ${lib.escapeShellArgs docFlags} \
        -j $NIX_BUILD_CORES \
        --target ${stdenv.hostPlatform.rust.rustcTargetSpec}
    '';

    postInstall = ''
      installShellCompletion --cmd fluree \
        --bash <($out/bin/fluree completions bash) \
        --fish <($out/bin/fluree completions fish) \
        --zsh <($out/bin/fluree completions zsh)

      docSrc=target/${stdenv.hostPlatform.rust.cargoShortTarget}/doc
      docOut=$doc/share/doc/fluree
      ${installDocs}
    '';

    meta = {
      description = "Semantic graph database with immutable ledger, SPARQL and Cypher query, and policy-based access control";
      homepage = "https://github.com/fluree/db";
      license = lib.licenses.bsl11;
      maintainers = [];
      mainProgram = "fluree";
    };
  }
