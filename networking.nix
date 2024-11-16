{ ... }:

{
  # Legacy DHCP deaktivieren
  networking.useDHCP = false;

  # Wir nutzen stattdessen systemd-networkd
  systemd.network = {
    enable = true;

    # Interface für Internet Zugang
    networks."10-internet" = {
      name = "enp0s3";
      DHCP = "yes";
    };

    # Interface für internen PSA Zugang
    networks."10-psa" = {
      name = "enp0s8";
      networkConfig.Domains = [ "psa-team06.cit.tum.de" ];
      networkConfig.DNS = "192.168.6.1";
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
      # Enable IPv4 (&IPv6) Forwarding
      networkConfig.IPForward = "yes";
    };
  };

  # systemd-resolved wird für korrektes DNS benötigt
  services.resolved.enable = true;

  # ICMP Redirects deaktivieren & IPv6
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
}

