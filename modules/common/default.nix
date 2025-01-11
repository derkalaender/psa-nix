# This file contains common options across all VMs

{ pkgs, lib, inputs, ... }:

{
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7qBxOWgSHhT1ZW5c/mNnOsPl5JT/5B3Yrmz1LjXx0Z fileserver"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTyrsqSn9oAlqyThh1VoIqLoOzNV5a9IAeERC09fAFU hey+ssh-2024-10@mrvnbr.de"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1bL8aC20ERDdJE2NqzIBvs8zXmCbFZ7fh5qXyqGNF7XfdfbsPBfQBSeJoncVfTJRFNYF4E+1Me918QMIpqa9XR4nJYOdOzff1JLYp1Z1X28Dx3//aOir8ziPCvGZShFDXoxLp6MNFIiEpI/IEW9OqxLhKj6YWVEDwK1ons7+pXnPM6Nd9lPd2UeqWWRpuuf9sa2AimQ1ZBJlnp7xHFTxvxdWMkTu6aH0j+aTT1w1+UDN2laS4nsmAJOO2KjeZq6xpbdmj9cjuxBJtM3Dsoq4ZJGdzez7XYhvCTQoQFl/5G0+4FBZeAgL/4ov12flGijZIIaXvmMBkLZRYg3E2m1Rp Praktikum Systemadministration"
    ];
  };

  nix = {
    settings = {
      # Enable Flakes and new nix cmd
      experimental-features = [ "nix-command" "flakes" ];
      # Give anyone with root access special permissions when talking to the Nix daemon
      trusted-users = [ "root" "@wheel"];
    };

    # Periodically gets rid of duplicate files in the store
    optimise.automatic = true;
    # Don't remove any dependencies needed to build alive (non-GC'd) packages
    extraOptions =
      ''
        keep-outputs = true
        keep-derivations = true
      '';
      
    # Disable channels
    channel.enable = false;
    # Make flake registry and nix path match flake inputs
    # This way, we can run things like `nix run nixpkgs#cowsay` or `nix run unstable#cowsay`
    registry = lib.mapAttrs (_: flake: {inherit flake;}) inputs;
    nixPath = lib.mapAttrsToList (name: _: "${name}=flake:${name}") inputs;

    # Use newer version of nix
    package = inputs.unstable.legacyPackages."x86_64-linux".nix;
  };

  # Correct timezone
  time.timeZone = "CET";

  # A few nice helpers
  environment.systemPackages = with pkgs; [
    micro # easy editor
    bat # better cat
    tlrc # easier man
    traceroute
    nmap
    netcat-gnu
    wget
    curlWithGnuTls
    dig
    htop
    bottom # better top
    gping # graphical ping
    tcpdump # TCP inspection
    dhcpdump # DHCP inspection
  ];

  # Message of the day - helps newcomers to NixOS
  users.motd =
    ''
      Welcome to this Server! We're running NixOS 24.05 here.

      You may notice that a lot of standard packages are missing.
      This is by design! You can easily use *ANY* package on this system :D
      Just run one of the following commands and replace "cowsay" with the package of your choice.
      If you need a more recent version, replace "nixpkgs" with "unstable"! 
      You can find all available packages here: https://search.nixos.org/packages?channel=24.05

      - Add a package temporarily to your shell: nix shell nixpkgs#cowsay
      - Run a package once with arguments: nix run nixpkgs#cowsay -- "Meow meow, I'm a cow"
      - Add a package permanently to your profile (not recommended): nix profile install nixpkgs#cowsay

      If you have any questions, check out our wiki pages or ask!
    '';
  security.pam.services = {
    sshd.showMotd = true;
    login.showMotd = true;
  };
  
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}
