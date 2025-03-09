{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.psa.monitoring;

  ssl = {
    crtFile = "/etc/ssl/grafana/grafana.crt";
    keyFile = "/etc/ssl/grafana/grafana.key";
  };
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
        retentionTime = "2d"; # Keep metrics for 2 days

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
            scheme = "https"; # Grafana is served only over HTTPS
            tls_config.insecure_skip_verify = true; # Certificate is self-signed
            static_configs = [
              {
                targets = [
                  "localhost:${toString config.services.grafana.settings.server.http_port}"
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
          server.protocol = "https";
          server.cert_file = ssl.crtFile;
          server.cert_key = ssl.keyFile;
          server.root_url = "https://psa.in.tum.de:60666"; # Public facing URL, used in alerts

          # Better performance
          server.enable_gzip = true;
          database.wal = true;
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
