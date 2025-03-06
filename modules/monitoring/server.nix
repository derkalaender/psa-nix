{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.psa.monitoring;
in {
  options = {
    psa.monitoring.server = {
      enable = mkEnableOption "Monitoring server consisting of Prometheus & Grafana";
    };
  };

  config = mkIf cfg.server.enable {
    services = {
      # Metrics collection
      prometheus = {
        enable = true;
        globalConfig = {
          scrape_interval = "15s"; # default is 1m, but we want more frequent updates
          evaluation_interval = "15s"; # default is 1m
        };

        # Collectors
        scrapeConfigs = [
          {
            # Prometheus itself
            job_name = "prometheus";
            static_configs = [
              {
                targets = [
                  "localhost:${toString config.services.prometheus.port}"
                ];
              }
            ];
          }
          {
            # Grafana
            job_name = "grafana";
            static_configs = [
              {
                targets = [
                  "localhost:${toString config.services.grafana.port}"
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

    # Make Grafana use proxy
    systemd.services.grafana.environment = {
      HTTP_PROXY = config.networking.proxy.httpProxy;
      HTTPS_PROXY = config.networking.proxy.httpProxy;
      NO_PROXY = config.networking.proxy.noProxy;
    };
  };
}
