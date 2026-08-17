# The Android SDK closure apps/mobile builds against, shared by apk.nix and by
# devShells.android in flake.nix so the two cannot drift.
#
# Not a package: it returns a plain attrset, which is only safe because
# packagesFromDirectoryRecursive stops at packages/pounce/package.nix and never
# looks at its siblings.
{
  path,
  stdenv,
}: let
  # androidenv wants a licence acceptance that has no business applying to the
  # package set the rest of the flake builds against, so it gets its own import.
  androidPkgs = import path {
    inherit (stdenv.hostPlatform) system;
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
  };

  # From the react-native pin apps/mobile carries — see that release's
  # gradle/libs.versions.toml, which is what expo-root-project reads. These move
  # when upstream bumps React Native, and Gradle says so loudly.
  buildToolsVersion = "36.0.0";
  ndkVersion = "27.1.12297006";

  # AGP 8.12's own default. Modules that never read rootProject.ext.ndkVersion —
  # expo-sqlite is one — fall back to it, and AGP answers a missing NDK by trying
  # to install one into the SDK, which here is a store path. Shipping both is
  # what stops that.
  agpDefaultNdkVersion = "27.0.12077973";

  composition = androidPkgs.androidenv.composeAndroidPackages {
    # 36 is what the app targets. The older pair is for autolinked community
    # modules that read their own safeExtGet default instead of the root
    # project's — react-native-true-sheet asks for 35.0.0 — and would otherwise
    # send AGP off to install it into the store the same way.
    platformVersions = ["36" "35"];
    buildToolsVersions = [buildToolsVersion "35.0.0"];
    includeNDK = true;
    ndkVersions = [ndkVersion agpDefaultNdkVersion];
    cmakeVersions = ["3.22.1"];
    includeEmulator = false;
    includeSystemImages = false;
    includeSources = false;
  };

  root = "${composition.androidsdk}/libexec/android-sdk";
in {
  inherit (composition) androidsdk;
  inherit root buildToolsVersion ndkVersion;

  env = {
    ANDROID_HOME = root;
    ANDROID_SDK_ROOT = root;
    ANDROID_NDK_ROOT = "${root}/ndk/${ndkVersion}";

    # AGP otherwise pulls its own aapt2 from Maven, and that binary is not
    # patched for NixOS. The one in build-tools is.
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${root}/build-tools/${buildToolsVersion}/aapt2";
  };
}
