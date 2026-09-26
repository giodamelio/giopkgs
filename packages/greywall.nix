{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  tun2socks,
  bubblewrap,
  socat,
  xdg-dbus-proxy,
  go,
}: let
  # greywall bind-mounts the embedded tun2socks into a bwrap sandbox that does
  # not see /nix/store, so it has to be static.
  tun2socksStatic = tun2socks.overrideAttrs (old: {
    env = (old.env or {}) // {CGO_ENABLED = "0";};
  });
in
  buildGoModule rec {
    pname = "greywall";
    version = "0.3.7";

    src = fetchFromGitHub {
      owner = "GreyhavenHQ";
      repo = "greywall";
      tag = "v${version}";
      hash = "sha256-8wcROYE+c03u/j5xRaClgBCxF3VWlsazMCvCjmpjBHg=";
    };

    vendorHash = "sha256-HT5Dl79B0XoVLEbTIRsnQHYQxKlIXgxy0C78WD5a/V0=";

    subPackages = ["cmd/greywall"];

    nativeBuildInputs = [makeWrapper];

    preBuild = ''
      install -Dm755 ${tun2socksStatic}/bin/tun2socks \
        internal/sandbox/bin/tun2socks-linux-${go.GOARCH}
    '';

    ldflags = [
      "-s"
      "-w"
      "-X main.version=${version}"
    ];

    postInstall = ''
      wrapProgram $out/bin/greywall \
        --suffix PATH : ${lib.makeBinPath [bubblewrap socat xdg-dbus-proxy]}
      ln -s greywall $out/bin/greywatch
    '';

    meta = {
      description = "Sandboxed command execution with network isolation";
      homepage = "https://github.com/GreyhavenHQ/greywall";
      license = lib.licenses.asl20;
      maintainers = [];
      mainProgram = "greywall";
      platforms = lib.platforms.linux;
    };
  }
