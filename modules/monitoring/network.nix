{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge;
  cfg = config.psa.monitoring;
in {
  config = mkMerge [
    (mkIf cfg.server.enable {
      services.prometheus.exporters.blackbox = {
        enable = true;
        configFile = ./configs/blackbox.yaml;
      };
    })
    {
      # Collectors
      services.prometheus.scrapeConfigs = [
        {
          # Network metrics
          job_name = "network ping";
          metrics_path = "/probe";
          params.module = ["ping"];
          static_configs = [
            {
              targets = cfg.targets.myIPs;
              labels = {
                group = "my";
              };
            }
            {
              targets = cfg.targets.routerIPs;
              labels = {
                group = "router";
              };
            }
          ];
          # This is needed so can route the targets to the Blackbox Exporter
          relabel_configs = [
            {
              source_labels = ["__address__"];
              target_label = "__param_target";
            }
            {
              source_labels = ["__param_target"];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "localhost:${toString config.services.prometheus.exporters.blackbox.port}";
            }
          ];
        }
      ];
    }
  ];
}
