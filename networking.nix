{ lib, pkgs, ... }:

{
  # Wir nutzen systemd-networkd
  systemd.network = {
  	enable = true;

  	# Interface für Internet Zugang
  	networks."10-internet" = {
  	  name = "enp0s3";
  	  DHCP = true;
  	};
  };
}

