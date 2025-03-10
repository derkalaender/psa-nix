{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.psa.mail;

  ssl = {
    cert = "/etc/ssl/mail/mail.crt";
    key = "/etc/ssl/mail/mail.key";
  };
in {
  options = {
    psa.mail.enable = lib.mkEnableOption "Mailserver";
  };

  config = lib.mkIf cfg.enable {
    services.postfix = {
      # Enable postfix
      enable = true;
      hostname = "meiru.psa-team06.cit.tum.de";
      domain = "psa-team06.cit.tum.de";
      origin = "$mydomain";
      destination = [
        "$mydomain"
        "$myhostname"
        "localhost.$mydomain"
        "localhost"
      ];
      networks = ["127.0.0.0/8" "192.168.6.0/24"];
      relayDomains = [
        "psa-team01.cit.tum.de"
        "psa-team02.cit.tum.de"
        "psa-team03.cit.tum.de"
        "psa-team04.cit.tum.de"
        "psa-team05.cit.tum.de"
        "psa-team07.cit.tum.de"
        "psa-team08.cit.tum.de"
        "psa-team09.cit.tum.de"
        "psa-team10.cit.tum.de"
      ];
      relayHost = "mailrelay.cit.tum.de";
      transport = ''
        psa-team01.cit.tum.de smtp:
        psa-team02.cit.tum.de smtp:
        psa-team03.cit.tum.de smtp:
        psa-team04.cit.tum.de smtp:
        psa-team05.cit.tum.de smtp:
        psa-team07.cit.tum.de smtp:
        psa-team08.cit.tum.de smtp:
        psa-team09.cit.tum.de smtp:
        psa-team10.cit.tum.de smtp:
      '';

      sslCert = ssl.cert;
      sslKey = ssl.key;

      # canonical = "/^(.*)@(.*\\.)?psa-team([0-9]+)\\.cit\\.tum\\.de/ \$1@cit\\.tum\\.de";

      # Redirect root and postmaster mail to ge65peq and ge59pib
      rootAlias = "ge65peq, ge59pib";
      postmasterAlias = "ge65peq, ge59pib";

      # Replace hostnames in from header
      enableHeaderChecks = true;
      headerChecks = [
        {
          pattern = "/^From:(.*)@.+?\\.psa-team([0-9]+)\\.cit\\.tum\\.de/";
          action = "REPLACE From:\${1}@psa-team\${2}.cit.tum.de";
        }
      ];

      mapFiles = {
        generic = ./generic;
      };

      # main.cf settings
      config = {
        # home_mailbox = "Maildir/";

        smtp_generic_maps = "regexp:/etc/postfix/generic";

        smtpd_helo_required = "yes";
        smtpd_helo_restrictions = [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          "reject_invalid_helo_hostname"
          "reject_unknown_helo_hostname"
        ];
        smtpd_recipient_restrictions = [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          "reject_unknown_recipient_domain"
          "reject_unauth_destination"
          "reject"
        ];
        smtpd_relay_restrictions = [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          "reject_unauth_destination"
        ];

        # use dovecot with sasl
        smtpd_sasl_type = "dovecot";
        smtpd_sasl_auth_enable = "yes";
        smtpd_sasl_local_domain = "$myhostname";
        smtpd_sasl_security_options = "noanonymous";
        smtpd_sasl_path = "/run/dovecot2/auth";
      };
    };

    # Virus filtering with clamav
    services.clamav = {
      daemon.enable = true;
      updater = {
        enable = true;
        settings = {
          HTTPProxyServer = "proxy.cit.tum.de";
          HTTPProxyPort = 8080;
        };
      };
    };

    # Spam & Virus filtering with rspamd
    services.rspamd = {
      enable = true;

      # Add rspamd to postfix
      postfix = {
        enable = true;
      };

      # Configure rspamd
      locals = {
        "milter_headers.conf" = {
          text = ''
            extended_spam_headers = true;
            skip_authenticated = false;
            skip_local = false;
          '';
        };

        "antivirus.conf" = {
          text = ''
            clamav {
              action = "reject";
              symbol = "CLAM_VIRUS";
              type = "clamav";
              log_clean = true;
              servers = "/run/clamav/clamd.ctl";
              scan_mime_parts = false;
            }
          '';
        };

        # Just for testing - remove afterwards
        "options.inc" = {
          text = ''
            gtube_patterns = "all";
          '';
        };

        "actions.conf" = {
          text = ''
            reject = null;
            greylist = null;
            discard = null;
            add_header = 6;
            rewrite_subject = 6;
          '';
        };
      };

      workers.rspamd_proxy = {
        type = "rspamd_proxy";
        bindSockets = [
          {
            socket = "/run/rspamd/rspamd-milter.sock";
            mode = "0664";
          }
        ];
        count = 1;
        extraConfig = ''
          milter = yes;
          timeout = 120s;

          upstream "local" {
            default = yes;
            self_scan = yes;
          }
        '';
      };
    };

    # Dovecot IMAP/POP3 server
    services.dovecot2 = {
      enable = true;
      enableImap = true;
      enablePop3 = true;
      sslServerCert = ssl.cert;
      sslServerKey = ssl.key;

      extraConfig = ''
        service auth {
            unix_listener auth {
              mode = 0660
              user = postfix
              group = postfix
            }
          }
      '';
    };

    environment.systemPackages = with pkgs; [
      neomutt
      swaks
    ];

    networking.firewall.allowedTCPPorts = [25 143 993 110 995]; # smtp imap imaps pop3 pop3s
  };
}
