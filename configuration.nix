# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./users.nix
      ./networking.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Btrfs mount optionen werden bei Generierung der hardware-config.nix nicht automatisch erkannt
  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [ "compress=zstd" "noatime" ];
  };
  
  # Zram aktivieren
  zramSwap.enable = true;
  
  # Hostname nach Schema festlegen
  networking.hostName = "vmpsateam06-01";
  
  # SSH aktivieren
  services.openssh.enable = true;
  # Nur mit SSH Key Anmeldung erlauben
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
  };

  users.mutableUsers = false;
  
  # Eigenen User erstellen mit Root-Rechten (wheel Gruppe)
  users.users.ge59pib = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];

    hashedPassword = "$y$j9T$nCKBejo5cQYZ4Z2GHtCsC0$Wx0.MRxfMaT4xBNwhp/1y/OlSFPGmfO5OtfDVOUWs09";
  
    # SSH Public-Key
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTyrsqSn9oAlqyThh1VoIqLoOzNV5a9IAeERC09fAFU hey+ssh-2024-10@mrvnbr.de"
    ];
  };

  users.users.ge65peq = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];

    hashedPassword = "$y$j9T$ozWdR.RlFFi9Nb/VNvx2g.$XA8Y3YZuLbI8t943rRWkkP5oxuYXId9FT5TcHK8v1.3";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBKmGZBpo2o5HMwSCOLVuznuaZ0ZdJgedaRyTYFxJzEK christian.sommer@tum.de"
    ];
  };

  users.users.root = { 
    hashedPassword = "$y$j9T$K1v9o13z11.rJz8LD7DO61$WGlzE.cXHjOvnSwJDMWcCvcTtEpwS7juyQ.vRWDgPS5";
  
    # SSH Public-Key
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTyrsqSn9oAlqyThh1VoIqLoOzNV5a9IAeERC09fAFU hey+ssh-2024-10@mrvnbr.de"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1bL8aC20ERDdJE2NqzIBvs8zXmCbFZ7fh5qXyqGNF7XfdfbsPBfQBSeJoncVfTJRFNYF4E+1Me918QMIpqa9XR4nJYOdOzff1JLYp1Z1X28Dx3//aOir8ziPCvGZShFDXoxLp6MNFIiEpI/IEW9OqxLhKj6YWVEDwK1ons7+pXnPM6Nd9lPd2UeqWWRpuuf9sa2AimQ1ZBJlnp7xHFTxvxdWMkTu6aH0j+aTT1w1+UDN2laS4nsmAJOO2KjeZq6xpbdmj9cjuxBJtM3Dsoq4ZJGdzez7XYhvCTQoQFl/5G0+4FBZeAgL/4ov12flGijZIIaXvmMBkLZRYg3E2m1Rp Praktikum Systemadministration"
    ];
  };

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true; # Gets rid of duplicate files in the store
    };
      
    # Disable channels
    channel.enable = false;
    # Make flake registry and nix path match flake inputs
    # This way, we can run things like `nix run nixpkgs#cowsay` or `nix run unstable#cowsay`
    registry = lib.mapAttrs (_: flake: {inherit flake;}) inputs;
    nixPath = lib.mapAttrsToList (name: _: "${name}=flake:${name}") inputs;
  };
  
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}

