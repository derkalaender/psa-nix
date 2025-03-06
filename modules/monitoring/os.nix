{
  config,
  lib,
  ...
}: let
  inherit (lib) mkMerge;
  cfg = config.psa.monitoring;
in {
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
    }

    {
      # Collectors
      services.prometheus.scrapeConfigs = [
        {
          # OS metrics
          job_name = "os";
          static_configs = [
            {
              targets = map (ip: "${ip}:${toString config.services.prometheus.exporters.node.port}") cfg.vms.myIPAll;
            }
          ];
        }
      ];
    }
  ];
}
