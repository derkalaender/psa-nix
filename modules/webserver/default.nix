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

  # Execute function for each user(name), returning attrSet
  forEachUsername = f: builtins.listToAttrs (map f (map (user: user.username) config.psa.users.psa));
  forEachUser = f:
    forEachUsername (
      u:
        f (builtins.getAttr u config.users.users)
    );
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
      forEachUsername (
        u: {
          name = "fcgiwrap-${u}";
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
      user: {
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
    );

    # Für jeden User erlauben wir o+x Permissions auf dem Home Directory
    users.users = forEachUsername (
      u: {
        name = u;
        value = {homeMode = "701";};
      }
    );

    # Activation Script um automatisch .html-data und .cgi-bin Ordner für jeden User zu erstellen
    system.activationScripts = forEachUser (
      user: {
        name = "webserver-user-${user.name}";
        value = {
          text = ''
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
            #!/usr/bin/env bash
            echo "Content-type: text/html"
            echo ""
            echo "👋 Hello dynamically from $(whoami)"
            echo "We also support: php (php-cgi), perl, python3, ruby. Just change the shebang!"
            EOF
              chmod +x "$cgi_bin_dir/index.sh"
              chown -R ${user.name}:${user.group} "$cgi_bin_dir"
            fi
          '';
          deps = ["users"];
        };
      }
    );

    # Script Packages installieren
    environment.systemPackages = scriptPkgs;

    # Allow commonly known script shebangs
    services.envfs.enable = true;

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
