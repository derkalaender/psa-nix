{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge;
in {
  imports = [
    ./openldap-exporter
  ];

  config = mkMerge [
    (mkIf config.psa.ldap.server.enable {
      services.prometheus.exporters.openldap = {
        enable = true;
        ldapURI = "ldapi:///var/run/openldap/ldapi";
        configFile = "/var/lib/openldap-exporter/config.yaml";
        scrapeInterval = "1s";
      };

      # Access to monitoring database in LDAP
      # See: https://www.ibm.com/docs/en/instana-observability/current?topic=technologies-monitoring-openldap
      services.openldap.settings.children = {
        "olcDatabase={2}Monitor".attrs = {
          objectClass = ["olcDatabaseConfig" "olcMonitorConfig"];
          olcDatabase = "{2}Monitor";

          # Root DN for complete monitoring access
          # See https://www.openldap.org/doc/admin24/backends.html#Monitor
          olcRootDN = "cn=monitoring,cn=Monitor";
          olcRootPW = "{SSHA}6jhGRYG9bcyKmL+TgH/iqmKzdwff6GQh";

          olcAccess = [
            # Allow monitoring access
            ''
              {0}to dn.subtree="cn=Monitor"
               by dn.exact="cn=monitoring,cn=Monitor" read
               by * none
            ''
          ];
        };
      };
    })
    {
      # Collectors
      services.prometheus.scrapeConfigs = [
        {
          # LDAP metrics
          job_name = "ldap";
          static_configs = [
            {
              targets = ["ldap.psa-team06.cit.tum.de:${toString config.services.prometheus.exporters.ldap.port}"];
            }
          ];
        }
      ];
    }
  ];
}
