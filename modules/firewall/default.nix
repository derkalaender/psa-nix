{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption optionalString;
  cfg = config.networking.firewall;

  portsToNftSet = ports: portRanges:
    lib.concatStringsSep ", " (
      map (x: toString x) ports ++ map (x: "${toString x.from}-${toString x.to}") portRanges
    );
in {
  options = {
    networking.firewall.allowForwarding = mkEnableOption "forwarding";
  };
  config = {
    ## FIREWALL ##

    # Disable built-in firewall
    networking.firewall.enable = false;

    # Enable nftables
    networking.nftables.enable = true;

    # Create our custom table
    networking.nftables.tables."filter".family = "inet";
    networking.nftables.tables."filter".content = ''
      set allowed_ips {
        type ifname . ipv4_addr
        flags interval
        elements = {
          "enp0s8" . 192.168.0.0/16, # PSA Intern
          "enp0s3" . 131.159.0.0/16, # FMI
          "enp0s3" . 129.187.254.49, # PAC Proxy
          "enp0s3" . 129.187.254.50, # PAC Proxy
          "enp0s3" . 188.68.47.93,   # Very Important Extern
        }
      }

      chain prerouting {
        type filter hook prerouting priority raw; policy accept; \
        comment "set untrack flag before ct hooked function";
        tcp dport { http, https } notrack
      }

      chain forward {
        type filter hook forward priority filter; policy drop;

        # Forward internal packets
        ${optionalString cfg.allowForwarding "iifname enp0s8 accept"}
      }

      chain input {
        type filter hook input priority filter; policy drop;

        # Allow already established or related connections
        ct state established,related accept

        # Allow loopback
        iif lo accept

        # Allow ICMP
        ip protocol icmp accept

        # Allow configured ports
        ${lib.concatStrings (
        lib.mapAttrsToList (
          iface: cfg: let
            ifaceExpr = lib.optionalString (iface != "default") "iifname ${iface}";
            tcpSet = portsToNftSet cfg.allowedTCPPorts cfg.allowedTCPPortRanges;
            udpSet = portsToNftSet cfg.allowedUDPPorts cfg.allowedUDPPortRanges;
          in ''
            ${lib.optionalString (tcpSet != "") "${ifaceExpr} tcp dport { ${tcpSet} } accept"}
            ${lib.optionalString (udpSet != "") "${ifaceExpr} udp dport { ${udpSet} } accept"}
          ''
        )
        cfg.allInterfaces
      )}
      }

      chain output {
        type filter hook output priority filter; policy drop;

        # Allow already established or related connections
        ct state established,related accept

        # Allow loopback
        oif lo accept

        # Allow ICMP
        ip protocol icmp accept

        # Allow IPs (without any restrictions on ports)
        oifname . ip daddr @allowed_ips accept
      }
    '';

    ## WEB PROXY ##
    networking.proxy = {
      httpProxy = "http://proxy.cit.tum.de:8080";
      httpsProxy = config.networking.proxy.httpProxy;
      noProxy = "localhost,127.0.0.1,192.168.0.0/16,psa-team01.cit.tum.de,psa-team02.cit.tum.de,psa-team03.cit.tum.de,psa-team04.cit.tum.de,psa-team05.cit.tum.de,psa-team06.cit.tum.de,psa-team07.cit.tum.de,psa-team08.cit.tum.de,psa-team09.cit.tum.de,psa-team10.cit.tum.de";
    };
  };
}
