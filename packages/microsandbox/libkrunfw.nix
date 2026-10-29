{
  lib,
  libkrunfw,
  fetchFromGitHub,
  fetchurl,
}: let
  # Must match KERNEL_VERSION in the fork's Makefile, which names the tarball.
  kernelVersion = "6.12.113";
in
  # microsandbox pins its own libkrunfw fork as the vendor/libkrunfw submodule
  # and resolves `libkrunfw.so.<LIBKRUNFW_VERSION>` by exact filename, so the
  # nixpkgs release cannot stand in for it. The nixpkgs recipe still fits; only
  # the source, kernel tarball and the curl line it rewrites differ.
  libkrunfw.overrideAttrs (finalAttrs: _old: {
    pname = "libkrunfw-microsandbox";
    version = "5.6.1";

    src = fetchFromGitHub {
      owner = "superradcompany";
      repo = "libkrunfw";
      rev = "70ff1e821a7b513adb391aef6ad538f6ce148c17";
      hash = "sha256-ukrmizk+OqxydWsP4JZiEzgZtLpSjDLGo4pspusfyuk=";
    };

    kernelSrc = fetchurl {
      url = "mirror://kernel/linux/kernel/v${lib.versions.major kernelVersion}.x/linux-${kernelVersion}.tar.xz";
      hash = "sha256-4JtnJ+XFISU/DUFpSQC5w4+3YE2301I4qBl6qffeJCg=";
    };

    postPatch = ''
      substituteInPlace Makefile \
        --replace-fail 'curl --fail --location --retry 5 --retry-delay 2 $(KERNEL_REMOTE) -o $(KERNEL_TARBALL)' \
                       'ln -s ${finalAttrs.kernelSrc} $(KERNEL_TARBALL)'
      patchShebangs scripts
    '';

    # update.nu writes both pins from the Makefile; a hand bump that misses one
    # should fail here rather than ship a library msb cannot find by name.
    preBuild = ''
      grep -qx 'KERNEL_VERSION = linux-${kernelVersion}' Makefile \
        || { echo "Makefile KERNEL_VERSION does not match kernelVersion ${kernelVersion}" >&2; exit 1; }
      grep -qx 'FULL_VERSION = ${finalAttrs.version}' Makefile \
        || { echo "Makefile FULL_VERSION does not match version ${finalAttrs.version}" >&2; exit 1; }
    '';
  })
