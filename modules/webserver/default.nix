{ config, lib, ... }:
let
  cfg = config.psa.webserver;

  sslKey = ./apache-selfsigned.key;
  sslCert = ./apache-selfsigned.crt;
in
{
  options = {
    psa.webserver.enable = lib.mkEnableOption "Apache Webserver";
  };

  config = lib.mkIf cfg.enable {
    services.httpd = {
      enable = true;
      enablePHP = true;

      # Hier definieren wir alle Hosts die erreichbar sein sollen. Lauschen alle auf 0.0.0.0
      virtualHosts = {
        "kumo.psa-team06.cit.tum.de" = {
          forceSSL = true;
          sslServerKey = sslKey;
          sslServerCert = sslCert;
        };

        "www.psa-team06.cit.tum.de" = {
          forceSSL = true;
          sslServerKey = sslKey;
          sslServerCert = sslCert;
        };

        "web.psa-team06.cit.tum.de" = {
          forceSSL = true;
          sslServerKey = sslKey;
          sslServerCert = sslCert;
        };
      };
    };

    # IP Adresse hinzufügen
    systemd.network.networks."10-psa".address = [ "192.168.6.69" ];
  };
}
