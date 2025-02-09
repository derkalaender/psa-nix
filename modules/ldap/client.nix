{
  config,
  lib,
  ...
}: let
  cfg = config.psa.ldap;
in {
  options = {
    psa.ldap.client = {
      enable = lib.mkEnableOption "LDAP client login";
    };
  };

  config = lib.mkIf cfg.client.enable {
    users.ldap = {
      enable = true;
      daemon.enable = true; # better performance
      base = cfg.server.baseDN;
      server = "ldap://${cfg.server.serverDomain}";
      useTLS = false;
      # Request, but don't validate the server's certificate
      # extraConfig = ''
      #   tls_reqcert allow
      # '';
    };
  };
}
