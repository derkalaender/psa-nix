{ config, lib, ... }:

{
  ## FIREWALL ##
  
  # Wir deaktivieren das Standard Firewall Modul unter NixOS, da wir alles selber konfigurieren
  networking.firewall.enable = false;

  # nftables aktivieren und auf Konfiguration verweisen
  networking.nftables = {
    enable = true;
    rulesetFile = ./nftables.conf;
  };


  ## WEB PROXY ##
  networking.proxy = {
    httpProxy = "http://proxy.cit.tum.de:8080";
    httpsProxy = config.networking.proxy.httpProxy;
    noProxy = "localhost,127.0.0.1,192.168.0.0/16,psa-team01.cit.tum.de,psa-team02.cit.tum.de,psa-team03.cit.tum.de,psa-team04.cit.tum.de,psa-team05.cit.tum.de,psa-team06.cit.tum.de,psa-team07.cit.tum.de,psa-team08.cit.tum.de,psa-team09.cit.tum.de,psa-team10.cit.tum.de";
  };
}
