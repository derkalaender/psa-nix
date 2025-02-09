{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.psa.ldap;

  # suffix for the database carrying all data entries
  baseDN = "dc=team06,dc=psa,dc=cit,dc=tum,dc=de";
  domain = "ldap.team06.psa.cit.tum.de";

  # root access
  rootName = "admin";
  rootPw = "{SSHA}REHwlTzaAcFssX+EYQwJ9rp0w9M80QMN";

  ssl = {
    crtFile = "/etc/ssl/openldap/slapd.crt";
    keyFile = "/etc/ssl/openldap/slapd.key";
  };

  customLDIF = ./custom.ldif;
in {
  options = {
    psa.ldap.server = {
      enable = lib.mkEnableOption "OpenLDAP server";
      baseDN = lib.mkOption {
        type = lib.types.str;
        default = baseDN;
        description = "Base DN for the LDAP server";
      };
      serverDomain = lib.mkOption {
        type = lib.types.str;
        default = domain;
        description = "URL for the LDAP server";
      };
    };
  };

  config = lib.mkIf cfg.server.enable {
    services.openldap = {
      enable = true;

      # Only allow secure connections
      urlList = ["ldapi:///" "ldaps:///" "ldap:///"];

      # Recursive configuration in on-line configuration (OLC) format
      # Starts implicitly with dn: cn=config
      # `attrs` are attributes for the current entry
      # `children` contains child entries
      # `includes` adds other ldif files
      settings = {
        attrs = {
          # activate more verbose logging
          olcLogLevel = ["stats" "conns" "config" "acl"];

          # SSL
          olcTLSCertificateFile = ssl.crtFile;
          olcTLSCertificateKeyFile = ssl.keyFile;
          olcTLSProtocolMin = "3.3";
          olcTLSCipherSuite = "DEFAULT:!kRSA:!kDHE";
        };

        children = {
          "cn=schema".includes = [
            # required
            "${pkgs.openldap}/etc/schema/core.ldif"
            # apparently required for nis to work
            "${pkgs.openldap}/etc/schema/cosine.ldif"
            "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
            # posixAccount & posixGroup
            "${pkgs.openldap}/etc/schema/nis.ldif"
            # our own schema
            customLDIF
          ];

          # Database
          "olcDatabase={1}mdb".attrs = {
            objectClass = ["olcDatabaseConfig" "olcMdbConfig"];
            olcDatabase = "{1}mdb";

            # Base DN for all entries in the database
            olcSuffix = baseDN;

            # Credentials for DN without access restrictions
            # Meta, doesn't actually need to exist in the database
            olcRootDN = "cn=${rootName},${baseDN}";
            olcRootPW = rootPw;

            # Directory to store the database in
            olcDbDirectory = "/var/lib/openldap/data";

            olcAccess = [
              # for testing: allow anyone to read anything
              ''
                {-1}to *
                 by * read
                 by * break
              ''
              # linux root user: full access
              ''
                {0}to *
                 by dn.exact=uidNumber=0+gidNumber=0,cn=peercred,cn=external,cn=auth manage
                 by * break
              ''
              # # anyone: use searching functionality
              # ''
              #   {1}to attrs=entry
              #    by * search break
              # ''
              # # anon: read UIDs
              # ''
              #   {2}to uid
              #    by anonymous read
              #    by * break
              # ''
              # users: write to various of their own properties
              ''
                {3}to attrs=cn,givenName,sn,nationality,street,postalCode,l,telephoneNumber,loginShell,userPassword,shadowLastChange
                 by self write
                 by * none
              ''
              # users: read all their own properties
              ''
                {4}to *
                 by self read
                 by * none
              ''
            ];
          };
        };
      };
    };
  };
}
