{
  config,
  lib,
  ...
}: let
  cfg = config.psa.ldap;

  sssdConf = builtins.readFile ./sssd.conf;
in {
  options = {
    psa.ldap.client = {
      enable = lib.mkEnableOption "LDAP client login";
    };
  };

  config = lib.mkIf cfg.client.enable {
    # System Security Services Daemon (SSSD) configuration
    services.sssd = {
      enable = true;
      config = sssdConf;
    };

    security.pam.services.login = {
      sssdStrictAccess = true;
      unixAuth = false;
    };
  };
}
