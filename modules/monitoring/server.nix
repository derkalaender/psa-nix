{
  config,
  lib,
  ...
}: let
  cfg = config.psa.monitoring;
in {
  options = {
    psa.monitoring.server = {
      enable = lib.mkEnableOption "Monitoring server consisting of Prometheus & Grafana";
    };
  };

  config = lib.mkIf cfg.server.enable {
    services = {
      # Metrics collection
      prometheus = {
        enable = true;
        globalConfig.scrape_interval = "20s"; # default is 1m, but we want more frequent updates

        # Collectors
        scrapeConfigs = [
          {
            job_name = "os";
            static_configs = [
              {
                targets = [
                  "localhost:9100"
                  "192.168.6.2:9100"
                  "192.168.6.3:9100"
                  "192.168.6.4:9100"
                  "192.168.6.5:9100"
                  "192.168.6.6:9100"
                  "192.168.6.7:9100"
                  "192.168.6.8:9100"
                  "192.168.6.9:9100"
                ];
              }
            ];
          }
        ];
      };

      # Metrics visualization
      grafana = {
        enable = true;
        settings = {
          server.http_addr = ""; # Listen on all interfaces
        };
      };
    };
  };
}
