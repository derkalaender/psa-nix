{
  config,
  lib,
  ...
}: let
  inherit (lib) mkMerge mkOption mkIf;
  cfg = config.psa.monitoring;
in {
  options = {
    psa.monitoring.os.openFirewall = mkOption {
      default = true;
      description = "Open firewall for Node Exporter";
    };
  };
  config = mkMerge [
    {
      services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [
          "systemd"
        ];
        disabledCollectors = [
          "textfile"
          "powersupplyclass"
          "tapestats"
          "thermal_zone"
        ];
      };

      networking.firewall.allowedTCPPorts = mkIf cfg.os.openFirewall [
        config.services.prometheus.exporters.node.port
      ];
    }

    {
      # Collectors
      services.prometheus.scrapeConfigs = [
        {
          # OS metrics
          job_name = "os";
          static_configs = [
            {
              targets = map (ip: "${ip}:${toString config.services.prometheus.exporters.node.port}") cfg.targets.myIPs;
            }
          ];
        }
      ];
    }
  ];
}
