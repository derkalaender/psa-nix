{
  config,
  lib,
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

      sslCert = ssl.cert;
      sslKey = ssl.key;

      # canonical = "/^(.*)@(.*\\.)?psa-team(\\d+)\\.cit\\.tum\\.de/ \${1}@cit\\.tum\\.de";
      # canonical = "/^(.*)@.+/ \${1}@cit\\.tum\\.de";

      # Maybe needed
      #transport = "";

      # Redirect root and postmaster mail to ge65peq and ge59pib
      rootAlias = "ge65peq, ge59pib";
      postmasterAlias = "ge65peq, ge59pib";

      # Replace hostnames in from header
      enableHeaderChecks = true;
      headerChecks = [
        {
          pattern = "/^From:(.*)@.+?\\.psa-team(\\d+)\\.cit\\.tum\\.de/";
          action = "REPLACE From:\${1}@psa-team\${2}.cit.tum.de";
        }
      ];

      # main.cf settings
      config = {
        smtpd_helo_required = "yes";
        smtpd_helo_restrictions = [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          "reject_invalid_helo_hostname"
          "reject_unknown_helo_hostname"
        ];
        smtpd_recipient_restrictions = [
          "reject_unknown_recipient_domain"
          "reject_unauth_destination"
          # "check_recipient_access $relay_domains"
          "permit_mynetworks"
          "permit_sasl_authenticated"
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

    # Spame filtering with rspamd
    services.rspamd = {
      enable = false;

      # Add rspamd to postfix
      postfix = {
        enable = true;
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
  };
}
