{config, ...}: let
  cfg = config.psa.monitoring;
in {
  config = {
    # Collectors
    services.prometheus.scrapeConfigs = [
      {
        # Database metrics
        job_name = "database";
        static_configs = [
          {
            targets = map (ip: "${ip}:9104") cfg.targets.databaseIPs;
          }
        ];
      }
    ];
  };
}
