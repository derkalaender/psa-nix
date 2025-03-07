{lib, ...}: let
  inherit (lib) mkOption types;
in {
  imports = [
    ./server.nix
    ./os.nix
    ./network.nix
    ./dns.nix
    ./dhcp.nix
    ./webserver.nix
    ./webapp.nix
  ];

  options = {
    psa.monitoring.vms = {
      myIPAll = mkOption {
        type = with types; listOf str;
        default = [];
      };
      routerIPAll = mkOption {
        type = with types; listOf str;
        default = [];
      };
      webserverURLs = mkOption {
        type = with types; listOf str;
        default = [];
      };
      webappURLs = mkOption {
        type = with types; listOf str;
        default = [];
      };
    };
  };

  config = {
    psa.monitoring.vms = {
      myIPAll = [
        "192.168.6.1"
        "192.168.6.2"
        "192.168.6.3"
        "192.168.6.4"
        "192.168.6.5"
        "192.168.6.6"
        "192.168.6.7"
        "192.168.6.8"
        "192.168.6.9"
      ];
      routerIPAll = [
        "192.168.1.18"
        "192.168.2.1"
        "192.168.3.3"
        "192.168.4.1"
        "192.168.5.1"
        "192.168.6.1"
        "192.168.7.1"
        "192.168.8.5"
        "192.168.9.10"
        "192.168.10.2"
      ];
      webserverURLs = [
        "https://kumo.psa-team06.cit.tum.de"
        "https://www.psa-team06.cit.tum.de"
        "https://web.psa-team06.cit.tum.de"
        "https://192.168.6.69"
        "https://kumo.psa-team06.cit.tum.de/~ge59pib"
        "https://kumo.psa-team06.cit.tum.de/~ge59pib/cgi-bin/index.sh"
        "https://kumo.psa-team06.cit.tum.de/~ge59pib/cgi-bin/wow.sh"
        "https://kumo.psa-team06.cit.tum.de/~ge59pib/cgi-bin/wow.php"
        "https://kumo.psa-team06.cit.tum.de/~ge59pib/cgi-bin/wow.py"
        "https://kumo.psa-team06.cit.tum.de/~ge59pib/cgi-bin/wow.pl"
        "https://kumo.psa-team06.cit.tum.de/~ge59pib/cgi-bin/wow.rb"
      ];
      webappURLs = [
        "https://psa.in.tum.de:60642"
        "https://psa.in.tum.de:60642/ghost/api/v3/admin/site/"
      ];
    };
  };
}
