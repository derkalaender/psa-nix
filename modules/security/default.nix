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
            # Logging
            stats.enable = true;
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
                      alert.tagged-packets = true;
                    }
                    {
                      anomaly.enabled = true;
                    }
                  ];
                };
              }
              {
                stats = {
                  enabled = true;
                  filename = "stats.log";
                  append = true;
                  totals = true;
                  threads = false;
                };
              }
            ];
            af-packet = let
              mkAfPacket = name: {
                interface = name;
                defrag = true;
                use-mmap = true;
                tpacket-v3 = true;
                cluster-id = 99;
                cluster-type = "cluster_flow";
              };
            in [
              (mkAfPacket "enp0s3")
              (mkAfPacket "enp0s8")
            ];
            pcap = let
              mkPcap = name: {interface = name;};
            in [
              (mkPcap "enp0s3")
              (mkPcap "enp0s8")
            ];
            app-layer = {
              protocols = {
                tls = {
                  enabled = "yes";
                  detection-ports.dp = [443];
                };
                ftp.enabled = "yes";
                rdp.enabled = "yes";
                ssh.enabled = "yes";
                smtp = {
                  enabled = "yes";
                  raw-extraction = false;
                  mime = {
                    decode-mime = true;
                    decode-base64 = true;
                    decode-quoted-prinatable = true;
                    header-value-depth = 2000;
                    extract-urls = true;
                    body-md5 = false;
                  };
                  inspected-tracker = {
                    content-limit = 100000;
                    content-inspect-min-size = 32768;
                    content-inspect-window = 4096;
                  };
                };
                imap.enabled = "detection-only";
                smb = {
                  enabled = "yes";
                  detection-ports.dp = [139 445];
                };
                nfs.enabled = "yes";
                tftp.enabled = "yes";
                dns.enabled = "yes";
                http = {
                  enabled = "yes";
                  libhtp.default-config = {
                    personality = "IDS";

                    # Can be specified in kb, mb, gb.  Just a number indicates
                    # it's in bytes.
                    request-body-limit = "100kb";
                    response-body-limit = "100kb";

                    # inspection limits
                    request-body-minimal-inspect-size = "32kb";
                    request-body-inspect-window = "4kb";
                    response-body-minimal-inspect-size = "40kb";
                    response-body-inspect-window = "16kb";

                    # response body decompression (0 disables)
                    response-body-decompress-layer-limit = "2";

                    # auto will use http-body-inline mode in IPS mode, yes or no set it statically
                    http-body-inline = "auto";

                    # Decompress SWF files.
                    # Two types: 'deflate', 'lzma', 'both' will decompress deflate and lzma
                    # compress-depth:
                    # Specifies the maximum amount of data to decompress,
                    # set 0 for unlimited.
                    # decompress-depth:
                    # Specifies the maximum amount of decompressed data to obtain,
                    # set 0 for unlimited.
                    swf-decompression = {
                      enabled = "yes";
                      type = "both";
                      compress-depth = "100kb";
                      decompress-depth = "100kb";
                    };

                    # Use a random value for inspection sizes around the specified value.
                    # This lowers the risk of some evasion techniques but could lead
                    # to detection change between runs. It is set to 'yes' by default.
                    #randomize-inspection-sizes: yes
                    # If "randomize-inspection-sizes" is active, the value of various
                    # inspection size will be chosen from the [1 - range%, 1 + range%]
                    # range
                    # Default value of "randomize-inspection-range" is 10.
                    #randomize-inspection-range: 10

                    # decoding
                    double-decode-path = false;
                    double-decode-query = false;
                  };
                };
                ntp.enabled = "yes";
                dhcp.enabled = "yes";
                telnet.enabled = "yes";
                modbus.enabled = "yes";
              };
            };
            unix-command.enabled = false;
          };
        };
      };

      systemd.services.suricata.serviceConfig = {
        TimeoutSec = 600;
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
