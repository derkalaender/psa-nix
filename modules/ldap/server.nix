{ config, lib, ... }:
let
  cfg = config.psa.ldap;
in
{
  options = {
    psa.ldap.server.enable = lib.mkEnableOption "OpenLDAP server";
  };

  config = lib.mkIf cfg.server.enable {
    services.openldap = {
      enable = true;

      # Only allow secure connections
      urlList = [ "ldapi:///" "ldaps:///" ];

      # Recursive configuration in on-line configuration (OLC) format
      settings = {
        attrs = {
          # TODO TLS
        };
      };
    };
  };
}
