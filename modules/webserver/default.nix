{ config, lib, ... }:
let
  cfg = config.psa.webserver;

  # Document roots, world-readable
  kumoSite = ./sites/kumo;
  wwwSite = ./sites/www;
  webSite = ./sites/web;

  # Gemeine SSL Attribute
  sslAttr = {
    forceSSL = true; # SSL redirect
    sslServerKey = ./apache-selfsigned.key;
    sslServerCert = ./apache-selfsigned.crt;
  };
in
{
  options = {
    psa.webserver.enable = lib.mkEnableOption "Apache Webserver";
  };

  config = lib.mkIf cfg.enable {
    services.httpd = {
      enable = true;
      enablePHP = true;
      extraModules = [
        "userdir"
      ];

      # Hier definieren wir alle Hosts die erreichbar sein sollen. Lauschen alle auf 0.0.0.0
      virtualHosts = {
        "kumo.psa-team06.cit.tum.de" = {
          documentRoot = kumoSite;
          # User Websites
          extraConfig =
            ''
              # Adapted from https://github.com/NixOS/nixpkgs/blob/7e1ca67996afd8233d9033edd26e442836cc2ad6/nixos/modules/services/web-servers/apache-httpd/default.nix#L249-L262
              UserDir .html-data
              UserDir disabled root
              <Directory "/home/*/.html-data">
                AllowOverride FileInfo AuthConfig Limit Indexes
                Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
                <Limit GET POST OPTIONS>
                  Require all granted
                </Limit>
                <LimitExcept GET POST OPTIONS>
                  Require all denied
                </LimitExcept>
              </Directory>
            '';
        } // sslAttr;

        "www.psa-team06.cit.tum.de" = {
          documentRoot = wwwSite;
        } // sslAttr;

        "web.psa-team06.cit.tum.de" = {
          documentRoot = webSite;
        } // sslAttr;
      };
    };

    # IP Adresse hinzufügen
    systemd.network.networks."10-psa".address = [ "192.168.6.69" ];
  };
}
