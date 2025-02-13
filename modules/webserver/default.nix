{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.psa.webserver;

  # Document roots, world-readable
  kumoSite = ./sites/kumo;
  wwwSite = ./sites/www;
  webSite = ./sites/web;

  # Gemeine SSL Attribute
  sslAttr = {
    forceSSL = true; # SSL redirect
    sslCertificateKey = "/etc/ssl/nginx/nginx.key";
    sslCertificate = "/etc/ssl/nginx/nginx.crt";
  };

  # Available script packages
  scriptPkgs = with pkgs; [bash perl php ruby python3Minimal];

  # Execute function for each user, returning attrSet
  forEachUser = f: builtins.listToAttrs (map f (config.psa.users.psa ++ config.psa.users.csv));
in {
  options = {
    psa.webserver.enable = lib.mkEnableOption "nginx Webserver";
  };

  config = lib.mkIf cfg.enable {
    systemd.services =
      {
        # Normalerweise darf Nginx nicht auf Home Ordner lesend zugreifen.
        # Das machen wir hier rückgängig
        nginx.serviceConfig.ProtectHome = "read-only";
      }
      //
      # fcgiwrap systemd service packages zum path hinzufügen
      forEachUser (
        u: {
          name = "fcgiwrap-${u.username}";
          value = {
            path = scriptPkgs;
          };
        }
      );

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;

      # Hier definieren wir alle Hosts die erreichbar sein sollen. Lauschen alle auf 0.0.0.0
      virtualHosts = {
        "kumo.psa-team06.cit.tum.de" =
          {
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
              extraConfig = ''
                fastcgi_pass unix:/run/fcgiwrap-$1.sock;
              '';
            };
          }
          // sslAttr;

        "www.psa-team06.cit.tum.de" =
          {
            root = wwwSite;
          }
          // sslAttr;

        "web.psa-team06.cit.tum.de" =
          {
            root = webSite;
          }
          // sslAttr;
      };

      # Logging
      commonHttpConfig = ''
        map $remote_addr $remote_addr_anon {
          ~(?P<ip>\d+\.\d+\.\d+)\.    $ip.0;
          default                     0.0.0.0;
        }

        log_format combined_anon '$remote_addr_anon - $remote_user [$time_local] '
                            '"$request" $status $body_bytes_sent '
                            '"$http_referer" "$http_user_agent"';

        # Log Locations spezifizieren
        # Access Log nimmt unser spezielles Log Format
        access_log /var/log/nginx/access.log combined_anon;
        error_log /var/log/nginx/error.log;
      '';
    };

    # Für jeden User wird eine fcgiwrap Service Instanz erzeugt
    services.fcgiwrap.instances = forEachUser (
      u: {
        name = u.username;
        value = {
          process = {
            user = u.username;
            group = "psa";
          };
          socket = {
            user = u.username;
            group = config.services.nginx.group;
            mode = "0660";
          };
        };
      }
    );

    # Each fcgiwrap socket needs have "nss-user-lookup.target" as target
    # Otherwise race condition: might start too early and LDAP users are not available yet
    systemd.sockets = forEachUser (
      u: {
        name = "fcgiwrap-${u.username}";
        value = {
          after = ["nss-user-lookup.target"];
          unitConfig = {
            DefaultDependencies = "no";
          };
        };
      }
    );

    # Not necessary with Fileserver anymore
    # # Für jeden User erlauben wir o+x Permissions auf dem Home Directory
    # users.users = forEachUser (
    #   u: {
    #     name = u.username;
    #     value = {homeMode = "701";};
    #   }
    # );

    # Activation Script um automatisch .html-data und .cgi-bin Ordner für jeden User zu erstellen
    # DEACTIVATED because we may not be able to access remote home directories
    # system.activationScripts = forEachUser (u:
    #   {
    #     name = "webserver-user-${u.username}";
    #     value = {
    #       text =
    #         ''
    #           html_data_dir="/home/${u.username}/.html-data"
    #           cgi_bin_dir="/home/${u.username}/.cgi-bin"

    #           if [ ! -d "$html_data_dir" ]; then
    #             mkdir -p "$html_data_dir"
    #             echo "👋 Hello statically from ${u.username}" > "$html_data_dir/index.html"
    #             chown -R ${u.username}:psa "$html_data_dir"
    #           fi

    #           if [ ! -d "$cgi_bin_dir" ]; then
    #             mkdir -p "$cgi_bin_dir"
    #             cat > "$cgi_bin_dir/index.sh" << 'EOF'
    #           #!/usr/bin/env bash
    #           echo "Content-type: text/html"
    #           echo ""
    #           echo "👋 Hello dynamically from $(whoami)"
    #           echo "We also support: php (php-cgi), perl, python3, ruby. Just change the shebang!"
    #           EOF
    #             chmod +x "$cgi_bin_dir/index.sh"
    #             chown -R ${u.username}:psa "$cgi_bin_dir"
    #           fi
    #         '';
    #       deps = [ "users" ];
    #     };
    #   }
    # );

    # Script Packages installieren
    environment.systemPackages = scriptPkgs;

    # Allow commonly known script shebangs
    # DOESN'T WORK WITH LDAP BASH SYMLINK
    # services.envfs.enable = true;

    systemd.tmpfiles.rules = [
      "L /bin/bash - - - - /run/current-system/sw/bin/bash"
      "L /bin/perl - - - - /run/current-system/sw/bin/perl"
      "L /bin/php-ci - - - - /run/current-system/sw/bin/php-cgi"
      "L /bin/ruby - - - - /run/current-system/sw/bin/ruby"
      "L /bin/python - - - - /run/current-system/sw/bin/python"
      "L /bin/python3 - - - - /run/current-system/sw/bin/python3"
    ];

    # IP Adresse hinzufügen
    systemd.network.networks."10-psa".address = ["192.168.6.69"];

    # Log Rotation
    # Default deaktivieren
    services.logrotate.settings.nginx.enable = lib.mkForce false;
    # Access Log
    services.logrotate.settings.nginxaccess = {
      files = "/var/log/nginx/access.log";
      frequency = "daily";
      su = "${config.services.nginx.user} ${config.services.nginx.group}";
      rotate = 5;
      compress = true;
      delaycompress = true;
      postrotate = "[ ! -f /var/run/nginx/nginx.pid ] || kill -USR1 `cat /var/run/nginx/nginx.pid`";
    };
    # Error Log
    services.logrotate.settings.nginxerror = {
      files = "/var/log/nginx/error.log";
      frequency = "daily";
      su = "${config.services.nginx.user} ${config.services.nginx.group}";
      rotate = 1;
      compress = true;
      delaycompress = true;
      postrotate = "[ ! -f /var/run/nginx/nginx.pid ] || kill -USR1 `cat /var/run/nginx/nginx.pid`";
    };
  };
}
