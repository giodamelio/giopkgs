{
  testers,
  netdata,
}: let
  authUUID = "11111111-2222-3333-4444-555555555555";
  baseSystemConfig = {pkgs, ...}: {
    environment.systemPackages = [pkgs.curl pkgs.jq netdata];

    # Shared secret - the streaming API key
    environment.etc."netdata-secrets/api-key".text = authUUID;

    networking.firewall.allowedTCPPorts = [19999];

    services.netdata = {
      enable = true;
      package = netdata;
    };
  };
in
  testers.runNixOSTest {
    name = "netdata-file-secrets";

    nodes = {
      parent = {pkgs, ...}: {
        imports = [baseSystemConfig];

        services.netdata = {
          # Parent accepts connections using API key from file as section header
          configDir."stream.conf" = pkgs.writeText "stream.conf" ''
            [file:/etc/netdata-secrets/api-key]
                enabled = yes
                allow from = *
          '';
        };
      };

      child = {pkgs, ...}: {
        imports = [baseSystemConfig];

        services.netdata = {
          # Child streams to parent using API key from file as value
          configDir."stream.conf" = pkgs.writeText "stream.conf" ''
            [stream]
                enabled = yes
                destination = parent:19999
                api key = file:/etc/netdata-secrets/api-key
          '';
        };
      };
    };

    testScript = ''
      start_all()

      # Wait for both netdata instances
      parent.wait_for_unit("netdata.service")
      parent.wait_for_open_port(19999)
      child.wait_for_unit("netdata.service")
      child.wait_for_open_port(19999)

      # Verify parent sees the child connection
      # This proves both file: references worked:
      # - Parent's section header [file:...] resolved to the API key
      # - Child's "api key = file:..." resolved to the same key
      # - They matched, so streaming authenticated successfully
      parent.wait_until_succeeds(
       "curl -s http://127.0.0.1:19999/api/v3/info | "
       "jq -e '.agents[0].nodes.receiving > 0'",
       timeout=30
      )
    '';
  }
