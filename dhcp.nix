{ inputs, ... }:
let
  # Custom Overlay um die neuste Version von Kea in nixpkgs zu forcen
  overlay-kea-unstable = final: prev: {
    kea = inputs.unstable.legacyPackages."x86_64-linux".kea;
  };
in
{
  # Overlay anwenden
  imports = [
    { nixpkgs.overlays = [ overlay-kea-unstable ]; }
  ];
  
  services.kea.dhcp4 = {
    enable = true;
    configFile = ./dhcp-conf.json;
  };
}
