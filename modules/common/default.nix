# This file contains common options across all VMs
{
  pkgs,
  lib,
  inputs,
  ...
}: {
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Btrfs mount optionen werden bei Generierung der hardware-config.nix nicht automatisch erkannt
  fileSystems = {
    "/".options = ["compress=zstd"];
    "/home".options = ["compress=zstd"];
    "/nix".options = ["compress=zstd" "noatime"];
  };

  # Zram aktivieren
  zramSwap.enable = true;

  # SSH aktivieren
  services.openssh.enable = true;
  # Nur mit SSH Key Anmeldung erlauben
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = true;
  };

  nix = {
    settings = {
      # Enable Flakes and new nix cmd
      experimental-features = ["nix-command" "flakes"];
      # Give anyone with root access special permissions when talking to the Nix daemon
      trusted-users = ["root" "@wheel"];
    };

    # Periodically gets rid of duplicate files in the store
    optimise.automatic = true;
    # Don't remove any dependencies needed to build alive (non-GC'd) packages
    extraOptions = ''
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
    python3
    openssl
  ];

  # Dynamic linking compat
  programs.nix-ld.enable = true;

  # Message of the day - helps newcomers to NixOS
  users.motd = ''
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

    Note to PSA users:
    - Your old home directories are still available under /oldhome/<username>.
    - You can find your initial login password under /oldhome/<username>/LDAP_PASSWORD and change it with "passwd".
    - You can find your certificate under /oldhome/<username>/LDAP_CERTIFICATE.key

    Others: Find the same files under your normal home directory.
  '';
  security.pam.services = {
    sshd.showMotd = true;
    login.showMotd = true;
  };

  # Enable LDAP login per default
  psa.ldap.client.enable = true;

  # Enable OS monitoring per default
  psa.monitoring.os.enable = true;

  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}
