{ inputs, config, lib, ... }:
let
  # Custom Overlay um die neuste Version von Kea in nixpkgs zu forcen
  overlay-kea-unstable = final: prev: {
    kea = inputs.unstable.legacyPackages."x86_64-linux".kea;
  };
  cfg = config.psa.dhcp;
in
{
  options = {
    psa.dhcp.enable = lib.mkEnableOption "Kea DHCP server";
  };
  
  # Overlay anwenden
  imports = [
    { nixpkgs.overlays = [ overlay-kea-unstable ]; }
  ];

  config = lib.mkIf cfg.enable {
    services.kea.dhcp4 = {
      enable = true;
      configFile = ./dhcp-conf.json;
    };
  };
}
