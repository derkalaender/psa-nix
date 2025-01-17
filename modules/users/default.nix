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

    # Create the users by mapping the TOML users array through the mkUser function and then converting it to an attribute set
    users.users = builtins.listToAttrs (map mkUser cfg.users.psa);

    # PSA User für andere Module bereitstellen, basierend auf TOML-Datei
    psa.users.psa = (trivial.importTOML ./users.toml).users;
  };
}
