{config, ...}: let
  cfg = config.psa.monitoring;
in {
  config = {
    # Collectors
    services.prometheus.scrapeConfigs = [
      {
        # Webapp metrics
        job_name = "webapp";
        metrics_path = "/probe";
        params.module = ["http_200"];
        static_configs = [
          {
            targets = cfg.vms.webserverURLs;
          }
        ];
        # This is needed so we can have the targets be the actual VMs but route all requests to blackbox locally
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
  };
}
