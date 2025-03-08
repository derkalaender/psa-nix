# https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/monitoring/prometheus/exporters.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkDefault mkForce mkEnableOption mkOption types concatStringsSep optionalString escapeShellArgs;
  name = "openldap";
  cfg = config.services.prometheus.exporters.openldap;
in {
  options = {
    services.prometheus.exporters.openldap = {
      enable = mkEnableOption "the prometheus ${name} exporter";
      port = mkOption {
        type = types.port;
        default = 9330;
        description = ''
          Port to listen on.
        '';
      };
      listenAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = ''
          Address to listen on.
        '';
      };
      user = mkOption {
        type = types.str;
        default = "${name}-exporter";
        description = ''
          User name under which the ${name} exporter shall be run.
        '';
      };
      group = mkOption {
        type = types.str;
        default = "${name}-exporter";
        description = ''
          Group under which the ${name} exporter shall be run.
        '';
      };
      ldapURI = mkOption {
        type = types.str;
        description = ''
          URI of the LDAP server. Accepts ldapi://, ldap://, or ldaps://.

          The default socket is located at /var/run/openldap/ldapi, so you can use ldapi:///var/run/openldap/ldapi.
        '';
      };
      scrapeInterval = mkOption {
        type = types.str;
        default = "15s";
        description = ''
          Scrape interval.
        '';
      };
      skipTLSVerify = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Skip TLS certificate verification.
        '';
      };
      configFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/var/lib/${name}-exporter/config.yaml";
        description = ''
          Path to the ${name} exporter configuration file.

          Specify the credentials for accessing the monitor database there like this:

          ---
          ldapUser: "cn=monitoring,cn=Monitor"
          ldapPass: "password"

          ::: {.warn}
          Please do not store this file in the nix store if you choose to include any credentials here,
          as it would be world-readable.
          :::
        '';
      };
      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Extra commandline options to pass to the ${name} exporter.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    systemd.services."prometheus-${name}-exporter" = let
      openldap-exporter = pkgs.callPackage ./openldap-exporter.nix {};
    in {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Restart = "always";
        PrivateTmp = true;
        WorkingDirectory = "/tmp";
        DynamicUser = true;
        User = cfg.user;
        Group = cfg.group;
        LoadCredential = mkIf (cfg.configFile != null) (mkForce ("config:" + cfg.configFile));
        # Start command
        ExecStart = concatStringsSep " " [
          "${openldap-exporter}/bin/openldap_exporter"
          "--promAddr=${cfg.listenAddress}:${toString cfg.port}"
          "--ldapAddr=${cfg.ldapURI}"
          "--interval=${toString cfg.scrapeInterval}"
          (optionalString cfg.skipTLSVerify "--ldapSkipInsecure")
          (optionalString (cfg.configFile != null) ''--config=''${CREDENTIALS_DIRECTORY}/config'')
          (escapeShellArgs cfg.extraFlags)
        ];
        # Hardening
        CapabilityBoundingSet = [""];
        DeviceAllow = [""];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = mkDefault "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"]; # might connect via Unix Socket
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };
  };
}
