{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge;
  cfg = config.psa.security;
in {
  options = {
    psa.security.ids.enable = lib.mkEnableOption "Intrusion Detection System";
  };

  config = mkMerge [
    (mkIf cfg.ids.enable {
      services = {
        suricata = {
          enable = true;
          settings = {
            af-packet = [
              {
                interface = "enp0s3";
                defrag = true;
                use-mmap = true;
                tpacket-v3 = true;
              }
              {
                interface = "enp0s8";
                defrag = true;
                use-mmap = true;
                tpacket-v3 = true;
              }
            ];
            app-layer = {
              protocols = {
                telnet.enabled = "yes";
                modbus.enabled = "yes";
                http.enabled = "yes";
                http2.enabled = "yes";
                tls.enabled = "yes";
                ssh.enabled = "yes";
                dns.enabled = "yes";
                nfs.enabled = "yes";
              };
            };
            outputs = [
              {
                fast = {
                  enabled = true;
                  filename = "fast.log";
                  append = true;
                };
              }
              {
                eve-log = {
                  enabled = true;
                  filetype = "regular";
                  filename = "eve.json";
                  community-id = true;
                  types = [
                    {
                      alert.tagged-packets = "yes";
                    }
                  ];
                };
              }
            ];
          };
        };
      };

      systemd.services.suricata-update.environment = {
        HTTP_PROXY = config.networking.proxy.httpProxy;
        HTTPS_PROXY = config.networking.proxy.httpProxy;
        NO_PROXY = config.networking.proxy.noProxy;
      };
    })
    {
      environment.systemPackages = with pkgs; [chkrootkit];
    }
  ];
}
