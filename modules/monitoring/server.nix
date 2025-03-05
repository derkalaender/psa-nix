{
  config,
  lib,
  pkgs,
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
