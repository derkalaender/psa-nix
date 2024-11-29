{ config, lib, ... }:
let
  cfg = config.psa.networking;
in
{
  options = {
  	psa.networking = {
  	  router = lib.mkOption {
  	  	type = lib.types.bool;
  	  	default = false;
  	  	description = "Marks this VM as the router VM. This enables packet forwarding and statically configures everything DNS and IP related. Also activates DNS and DHCP modules.";
  	  };
  	};
  };

  config = {
    # Legacy DHCP deaktivieren
    networking.useDHCP = false;

    # Wir nutzen stattdessen systemd-networkd
    systemd.network = {
      enable = true;

	  # Interface für Internet Zugang
	  networks."10-internet" = {
        name = "enp0s3";
        DHCP = "yes"; # Wir brauchen eine IP-Adresse für Internet Zugang.
        dhcpV4Config = {
          # Wir wollen weder den DNS Server noch die Domain durch dieses Interface festlegen.
          # Das soll nur durch unseren eigenen DHCP Server getan werden.
          UseDNS = false;
          UseDomains = false;
        };
      };

      # Interface für internes PSA Netz
      networks."10-psa" = lib.mkMerge [
        {
          name = "enp0s8";
        }
        # Falls wir kein Router sind, legen wir alles über DHCP (mit AllowList) fest
        (lib.mkIf (!cfg.router) {
          DHCP = "ipv4";
          dhcpV4Config.UseDomains = true;
          # AllowList kann man noch nicht direkt einstellen
          extraConfig =
            ''
            [DHCPv4]
            AllowList=192.168.6.1
            '';
        })

        # Falls wir Router sind, legen wir die gesamte Konfiguration statisch fest    
        (lib.mkIf cfg.router {
          domains = [ "psa-team06.cit.tum.de" ];
          dns = [ "192.168.6.1" ];
          address = [
            "192.168.6.1/24" # Team Subnet
            # Restliche Inter-PSA Subnets
            "192.168.61.6/24"
            "192.168.62.6/24"
            "192.168.63.6/24"
            "192.168.64.6/24"
            "192.168.65.6/24"
            "192.168.76.6/24"
            "192.168.86.6/24"
            "192.168.96.6/24"
            "192.168.106.6/24"
          ];
          routes = [
            { routeConfig = { Destination = "192.168.1.0/24"; Gateway = "192.168.61.1"; }; }
            { routeConfig = { Destination = "192.168.2.0/24"; Gateway = "192.168.62.2"; }; }
            { routeConfig = { Destination = "192.168.3.0/24"; Gateway = "192.168.63.3"; }; }
            { routeConfig = { Destination = "192.168.4.0/24"; Gateway = "192.168.64.4"; }; }
            { routeConfig = { Destination = "192.168.5.0/24"; Gateway = "192.168.65.5"; }; }
            { routeConfig = { Destination = "192.168.7.0/24"; Gateway = "192.168.76.7"; }; }
            { routeConfig = { Destination = "192.168.8.0/24"; Gateway = "192.168.86.8"; }; }
           { routeConfig = { Destination = "192.168.9.0/24"; Gateway = "192.168.96.9"; }; }
            { routeConfig = { Destination = "192.168.10.0/24"; Gateway = "192.168.106.10"; }; }
          ];
          # IPv4 (&IPv6) Forwarding aktivieren
          networkConfig.IPForward = "yes";
        })
      ];
    };

    # systemd-resolved wird für korrektes DNS benötigt
    services.resolved.enable = true;
    
    # ICMP Redirects deaktivieren & IPv6 auch
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.send_redirects" = false;
      "net.ipv4.conf.default.send_redirects" = false;
      "net.ipv6.conf.all.send_redirects" = false;
      "net.ipv6.conf.default.send_redirects" = false;
      "net.ipv4.conf.all.accept_redirects" = false;
      "net.ipv4.conf.default.accept_redirects" = false;
      "net.ipv6.conf.all.accept_redirects" = false;
      "net.ipv6.conf.default.accept_redirects" = false;
       
      "net.ipv6.conf.all.disable_ipv6" = true;
      "net.ipv6.conf.default.disable_ipv6" = true;
    };

    # Als Router stellen wir auch DNS und DHCP bereit
    psa = lib.mkIf cfg.router {
      dns.enable = true;
      dhcp.enable = true;
    };

    # Durch diese Einstellung wird per Default der Hostname über DHCP bezogen.
    # Kann einfach überschrieben werden (z.B. beim Router)
    networking.hostName = lib.mkDefault "";
  };
}
