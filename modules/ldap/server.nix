
{ config, lib, pkgs, ... }:
let
  cfg = config.psa.ldap;

  # suffix for the database carrying all data entries
  baseDN = "dc=team06,dc=psa,dc=cit,dc=tum,dc=de";
  rootName = "admin";
  rootPw = "{SSHA}REHwlTzaAcFssX+EYQwJ9rp0w9M80QMN";
in
{
  options = {
    psa.ldap.server.enable = lib.mkEnableOption "OpenLDAP server";
  };

  config = lib.mkIf cfg.server.enable {
    services.openldap = {
      enable = true;

      # Only allow secure connections
      urlList = [ "ldapi:///" "ldaps:///" ];

      # Recursive configuration in on-line configuration (OLC) format
      # Starts with dn: cn=config
      # `attrs` are attributes for the current entry
      # `children` contains child entries
      # `includes` adds other ldif files
      settings = {
        attrs = {
          # activate more verbose logging
          olcLogLevel = [ "stats" "conns" "config" "acl" ];

          # SSL
          olcTLSCertificateFile = "/etc/ssl/openldap/slapd.crt";
          olcTLSCertificateKeyFile = "/etc/ssl/openldap/slapd.key";
          olcTLSProtocolMin = "3.3";
          olcTLSCipherSuite = "DEFAULT:!kRSA:!kDHE";
        };

        children = {
          "cn=schema".includes = [
            # required
            "${pkgs.openldap}/etc/schema/core.ldif"
          ];

          # Database
          "olcDatabase={1}mdb".attrs = {
            objectClass = [ "olcDatabaseConfig" "olcMdbConfig" ];
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
              # allow root linux user complete access
              ''{0}to *
                  by dn.exact=uidNumber=0+gidNumber=0,cn=peercred,cn=external,cn=auth manage
                  by * break''
            ];
          };
        };
      };
    };
  };
}
