{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.psa;

  # Create a single user from an element of the users TOML array.
  # We use the special attributes "name" and "value" here which allow
  # converting to an attribute set.
  mkUser = user: {
    name = user.username;
    value = {
      isNormalUser = true;
      uid = user.uid;
      group = "psa";
      openssh.authorizedKeys.keys = singleton user.sshKey;
    };
  };
in {
  options = {
    psa.users.psa = mkOption {
      type = with types;
        listOf (submodule {
          options = {
            username = mkOption {
              type = str;
              description = "Username of the user";
            };
            uid = mkOption {
              type = int;
              description = "UID of the user";
            };
            sshKey = mkOption {
              type = nullOr str;
              default = null;
              description = "The user's SSH public key";
            };
            filemount = mkOption {
              type = nullOr str;
              default = null;
              description = "The user's filemount";
            };
          };
        });
      default = [];
      description = "PSA users";
    };
  };

  config = {
    # Gruppe "psa" erstellen
    users.groups.psa = {
      gid = 1000;
    };

    # Add users to wheel group manually for sudo
    users.groups.wheel.members = [
      "ge59pib"
      "ge65peq"
    ];

    # Don't allow useradd/userdel commands
    users.mutableUsers = false;

    # Manage root user
    users.users.root = {
      hashedPassword = "$y$j9T$K1v9o13z11.rJz8LD7DO61$WGlzE.cXHjOvnSwJDMWcCvcTtEpwS7juyQ.vRWDgPS5";

      # SSH Public-Key
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7qBxOWgSHhT1ZW5c/mNnOsPl5JT/5B3Yrmz1LjXx0Z fileserver"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTyrsqSn9oAlqyThh1VoIqLoOzNV5a9IAeERC09fAFU hey+ssh-2024-10@mrvnbr.de"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBKmGZBpo2o5HMwSCOLVuznuaZ0ZdJgedaRyTYFxJzEK christian.sommer@tum.de"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1bL8aC20ERDdJE2NqzIBvs8zXmCbFZ7fh5qXyqGNF7XfdfbsPBfQBSeJoncVfTJRFNYF4E+1Me918QMIpqa9XR4nJYOdOzff1JLYp1Z1X28Dx3//aOir8ziPCvGZShFDXoxLp6MNFIiEpI/IEW9OqxLhKj6YWVEDwK1ons7+pXnPM6Nd9lPd2UeqWWRpuuf9sa2AimQ1ZBJlnp7xHFTxvxdWMkTu6aH0j+aTT1w1+UDN2laS4nsmAJOO2KjeZq6xpbdmj9cjuxBJtM3Dsoq4ZJGdzez7XYhvCTQoQFl/5G0+4FBZeAgL/4ov12flGijZIIaXvmMBkLZRYg3E2m1Rp Praktikum Systemadministration"
      ];
    };

    # Managed by LDAP now
    # # Create the users by mapping the TOML users array through the mkUser function and then converting it to an attribute set
    # users.users = builtins.listToAttrs (map mkUser cfg.users.psa);

    # PSA User für andere Module bereitstellen, basierend auf TOML-Datei
    psa.users.psa = (trivial.importTOML ./users.toml).users;
  };
}
