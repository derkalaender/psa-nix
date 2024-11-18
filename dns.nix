{ ... }:
let
  zones = ./zones;
in
{
  services.coredns = {
    enable = true;
    config =
      ''
        (common) {
                bind enp0s8
                root ${zones}
                log
                errors
                nsid https://youtu.be/xvFZjo5PgG0
        }
        
        . {
                # Normaler traffic soll an die internen Nameserver weitergeleitet werden
                forward . 131.159.254.1 131.159.254.2
        
                # Haha funny DNS
                chaos UwU Marv Chris
        
                import common
        }
        
        # Unser Team DNS
        psa-team06.cit.tum.de {
                file psa-team06.zone
                transfer {
                        to 192.168.5.1
                        to 192.168.65.5
                        to 192.168.7.1
                        to 192.168.76.7
                }
                import common
        }
        
        # Unser Team Reverse DNS
        6.168.192.in-addr.arpa {
                file 6.168.192.zone
                transfer {
                        to 192.168.5.1
                        to 192.168.65.5
                        to 192.168.7.1
                        to 192.168.76.7
                }
                import common
        }
        
        
        ### OTHER TEAMS FORWARDING ###
        
        psa-team01.cit.tum.de 1.168.192.in-addr.arpa {
                forward . 192.168.1.1
                import common
        }
        
        psa-team02.cit.tum.de 2.168.192.in-addr.arpa {
                forward . 192.168.2.1
                import common
        }
        
        psa-team03.cit.tum.de 3.168.192.in-addr.arpa {
                forward . 192.168.3.1
                import common
        }
        
        psa-team04.cit.tum.de 4.168.192.in-addr.arpa {
                forward . 192.168.4.1
                import common
        }
        
        psa-team05.cit.tum.de 5.168.192.in-addr.arpa {
                secondary {
                        transfer from 192.168.5.1
                }
                forward . 192.168.5.1
                import common
        }
        
        psa-team07.cit.tum.de 7.168.192.in-addr.arpa {
                secondary {
                        transfer from 192.168.7.1
                }
                forward . 192.168.7.1
                import common
        }
        
        psa-team08.cit.tum.de 8.168.192.in-addr.arpa {
                forward . 192.168.8.6
                import common
        }
        
        psa-team09.cit.tum.de 9.168.192.in-addr.arpa {
                forward . 192.168.9.1
                import common
        }
        
        psa-team10.cit.tum.de 10.168.192.in-addr.arpa {
                forward . 192.168.10.2
                import common
        }
      '';
  };
}
