{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge;
  cfg = config.psa.security;
in {
  options = {
    psa.security.ids.enable = lib.mkEnableOption "Intrusion Detection System";
  };

  config = mkMerge [
    (mkIf cfg.ids.enable {
      # environment.systemPackages = with pkgs; [snort];
    })
    {
      environment.systemPackages = with pkgs; [chkrootkit];
    }
  ];
}
