{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge;
in {
  config = mkMerge [
    (mkIf config.psa.dhcp.enable {
      services.prometheus.exporters.kea = {
        enable = true;
        targets = ["/run/kea/kea-dhcp4.socket"];
      };
    })
    {
      # Collectors
      services.prometheus.scrapeConfigs = [
        {
          # DHCP metrics
          job_name = "dhcp";
          static_configs = [
            {
              targets = ["localhost:${toString config.services.prometheus.exporters.kea.port}"];
            }
          ];
        }
      ];
    }
  ];
}
