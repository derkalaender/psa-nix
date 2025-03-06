{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge mkEnableOption;
  cfg = config.psa.monitoring;
in {
  options = {
    psa.monitoring.os = {
      enable = mkEnableOption "Node exporter for monitoring basic OS metrics";
    };
  };

  config = mkMerge [
    (mkIf cfg.os.enable {
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
    })
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
