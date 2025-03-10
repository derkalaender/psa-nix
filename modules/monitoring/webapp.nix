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
            targets = cfg.targets.webappURLs;
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
  };
}
