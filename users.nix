{ lib, ... }:

with lib;

let
  # Get the users array from the users.toml file
  users = (trivial.importTOML ./users.toml).users;

  # Create a single user from an element of the users TOML array.
  # We use the special attributes "name" and "value" here which allow
  # converting to an attribute set.
  mkUser = user: {
    name = user.username;
    value = {
      isNormalUser = true;
      uid = user.uid;
      group = "psa";
      openssh.authorizedKeys.keys = lists.optional (user.ssh_key != "") user.ssh_key; # create a list with the key if it exists, empty list otherwise
    };
  };
in
{
  # Gruppe "psa" erstellen
  users.groups.psa = {
  	gid = 1000;
  };

  # Create the users by mapping the TOML users array through the mkUser function and then converting it to an attribute set
  users.users = builtins.listToAttrs (map mkUser users);
}
