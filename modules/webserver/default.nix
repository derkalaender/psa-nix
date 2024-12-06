{ config, lib, pkgs, ... }:
let
  cfg = config.psa.webserver;

  # Document roots, world-readable
  kumoSite = ./sites/kumo;
  wwwSite = ./sites/www;
  webSite = ./sites/web;

  # Gemeine SSL Attribute
  sslAttr = {
    forceSSL = true; # SSL redirect
    sslCertificateKey = ./apache-selfsigned.key;
    sslCertificate = ./apache-selfsigned.crt;
  };
in
{
  options = {
    psa.webserver.enable = lib.mkEnableOption "nginx Webserver";
  };

  config = lib.mkIf cfg.enable {
    # Normalerweise darf Nginx nicht auf Home Ordner lesend zugreifen.
    # Das machen wir hier rückgängig
    systemd.services.nginx.serviceConfig.ProtectHome = "read-only";
    
    services.nginx = {
      enable = true;
      recommendedOptimisation = true;

      # Hier definieren wir alle Hosts die erreichbar sein sollen. Lauschen alle auf 0.0.0.0
      virtualHosts = {
        "kumo.psa-team06.cit.tum.de" = {
          root = kumoSite;

          # http://.../~<login> -> ~<login>/.html-data
          locations."~ ^/~(\\w+?)(?:/(.*))?$" = {
            priority = 2;
            alias = "/home/$1/.html-data/$2";
          };

          # http://.../~<login>/cgi-bin -> ~<login>/.cgi-bin
          locations."~ ^/~(\\w+?)/cgi-bin(?:/(.*))?$" = {
            priority = 1;
            fastcgiParams.SCRIPT_FILENAME = "/home/$1/.cgi-bin/$2";
            extraConfig =
              ''
                fastcgi_pass unix:/run/fcgiwrap-$1.sock;
              '';
          };
        } // sslAttr;

        "www.psa-team06.cit.tum.de" = {
          root = wwwSite;
        } // sslAttr;

        "web.psa-team06.cit.tum.de" = {
          root = webSite;
        } // sslAttr;
      };
    };

    # Für jeden User wird eine fcgiwrap Service Instanz erzeugt
    services.fcgiwrap.instances = builtins.listToAttrs (map
      (u:
        let
          user = builtins.getAttr u config.users.users;
        in
          {
            name = user.name;
            value = {
              process = {
                user = user.name;
                group = user.group;
              };
              socket = {
                user = user.name;
                group = config.services.nginx.group;
                mode = "0660";
              };
            };
          }
      )
      config.psa.users.psa
    );

    # Für jeden User erlauben wir o+x Permissions auf dem Home Directory
    users.users = builtins.listToAttrs (map
      (u:
        {
          name = u;
          value = { homeMode = "701"; };
        }
      )
      config.psa.users.psa
    );

    # Activation Script um automatisch .html-data und .cgi-bin Ordner für jeden User zu erstellen
    system.activationScripts = builtins.listToAttrs (map
      (u:
        let
          user = builtins.getAttr u config.users.users;
        in
          {
            name = "webserver-user-${user.name}";
            value = {
              text =
                ''
                  html_data_dir="${user.home}/.html-data"
                  cgi_bin_dir="${user.home}/.cgi-bin"

                  if [ ! -d "$html_data_dir" ]; then
                    mkdir -p "$html_data_dir"
                    echo "👋 Hello statically from ${user.name}" > "$html_data_dir/index.html"
                    chown -R ${user.name}:${user.group} "$html_data_dir"
                  fi

                  if [ ! -d "$cgi_bin_dir" ]; then
                    mkdir -p "$cgi_bin_dir"
                    cat > "$cgi_bin_dir/index.sh" << 'EOF'
                  #!/run/current-system/sw/bin/bash
                  echo "Content-type: text/html"
                  echo "👋 Hello dynamically from $(whoami)"
                  EOF
                    chmod +x "$cgi_bin_dir/index.sh"
                    chown -R ${user.name}:${user.group} "$cgi_bin_dir"
                  fi
                '';
              deps = [ "users" ];
            };
          }
      )
      config.psa.users.psa
    );

    system.environmentPackages = with pkgs; [
      bash
      perl
      php
      ruby
      python3Minimal  
    ];

    # IP Adresse hinzufügen
    systemd.network.networks."10-psa".address = [ "192.168.6.69" ];
  };
}
