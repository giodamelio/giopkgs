{
  lib,
  callPackage,
}: let
  fluree = callPackage ./fluree.nix {};
in
  # Derived from the fluree derivation rather than rebuilt beside it, so the
  # source, the vendored deps, the rustdoc flags and the rustc/cargo that
  # buildRustPackage settled on are shared by construction.
  fluree.overrideAttrs (old: {
    pname = "fluree-docs";

    # buildRustPackage derives the vendor derivation's name from finalAttrs.pname,
    # which overrideAttrs feeds back into, so renaming alone would re-fetch the
    # same 8500-crate lockfile under a second store path. Pin the original.
    inherit (fluree) cargoDeps;

    outputs = ["out"];

    # Stock dev is debug = true, so every build script and proc macro would carry
    # debug info nothing here reads. Merged rather than replaced — buildRustPackage
    # puts RUST_LOG and the RUSTFLAGS guard in env.
    env = old.env // {CARGO_PROFILE_DEV_DEBUG = "false";};

    # Passing no --target leaves cargo on its default dev profile instead of the
    # workspace release profile (lto = true, codegen-units = 1). rustdoc only
    # needs the crates to compile, not to be optimized or linked, and skipping
    # that is the whole reason this exists apart from fluree's `doc` output.
    buildPhase = ''
      runHook preBuild

      cargo doc --offline ${lib.escapeShellArgs fluree.docFlags} \
        -j $NIX_BUILD_CORES

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      docSrc=target/doc
      docOut=$out/share/doc/fluree
      ${fluree.installDocs}

      runHook postInstall
    '';

    # fluree.nix's own doc pass targets the release profile, and its postInstall
    # runs a binary this derivation never builds.
    postBuild = "";
    postInstall = "";

    meta =
      builtins.removeAttrs old.meta ["mainProgram"]
      // {
        description = "Rustdoc HTML for every crate in the Fluree DB workspace, which publishes none of them";
      };
  })
