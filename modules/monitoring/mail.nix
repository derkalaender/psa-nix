{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge;
in {
  config = mkMerge [
    (mkIf config.psa.mail.enable {
      services.prometheus.exporters.postfix = {
        enable = true;
      };
    })
    {
      # Collectors
      services.prometheus.scrapeConfigs = [
        {
          # Mail metrics
          job_name = "mail";
          static_configs = [
            {
              targets = ["meiru.psa-team06.cit.tum.de:${toString config.services.prometheus.exporters.postfix.port}"];
            }
          ];
        }
      ];
    }
  ];
}
