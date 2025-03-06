{
  config,
  lib,
  ...
}: let
  cfg = config.psa.monitoring;
in {
  options = {
    psa.monitoring.os = {
      enable = lib.mkEnableOption "Enable node exporter for monitoring basic OS metrics";
    };
  };

  config = lib.mkIf cfg.os.enable {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        "systemd"
        "logind"
        "mountstats"
      ];
      disabledCollectors = ["textfile"];
    };
  };
}
