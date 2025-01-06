{ config, lib, ... }:
let
  cfg = config.psa.ldap;
in
{
  imports = [
    ./server.nix
    ./client.nix
  ];
}
