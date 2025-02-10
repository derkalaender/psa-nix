{
  config,
  lib,
  ...
}: let
  cfg = config.psa.ldap;

  sssdConf = builtins.readFile ./sssd.conf;

  pamConf = {
    sssdStrictAccess = false;
    unixAuth = lib.mkForce false;
  };
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
      environmentFile = "/etc/secrets/sssd.env";
    };

    security.pam.services = {
      # sshd = pamConf;
      passwd = pamConf;
      chpasswd = pamConf;
      login = pamConf;
      # su = pamConf;
      # sudo = pamConf;
    };
  };
}
