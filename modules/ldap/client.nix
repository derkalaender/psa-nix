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
      environmentFile = "/etc/secrets/sssd.env";
    };

    # LDAP entries reference /bin/bash
    # This doesn't exist in NixOS, instead its under /run/current-system/sw/bin/bash
    # This symlink fixes sshd login
    # Other shells might need similar treatment if used
    systemd.tmpfiles.rules = [
      "L /bin/bash - - - - /run/current-system/sw/bin/bash"
    ];
  };
}
