{...}: {
  config = {
    # Collectors
    services.prometheus.scrapeConfigs = [
      {
        # DNS metrics
        job_name = "dns";
        static_configs = [
          {
            targets = ["localhost:9153"];
          }
        ];
      }
    ];
  };
}
