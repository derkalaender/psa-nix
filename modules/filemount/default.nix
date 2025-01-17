{config, ...}: let
  cfg = config.psa;

  idleTimeout = "60s"; # how long a mount should be kept around after it's last use
  failTimeout = "5s"; # how long to wait for a mount to succeed before giving up

  usersWithFilemount = builtins.filter (user: !(isNull user.filemount)) cfg.users.psa;
  forEachUserPath = f: builtins.listToAttrs (map f usersWithFilemount);
in {
  fileSystems = forEachUserPath (
    user: {
      name = "/home/${user.username}";
      value = {
        device = user.filemount;
        fsType = "nfs";
        options = [
          "x-systemd.automount"
          "noauto"
          "x-systemd.idle-timeout=${idleTimeout}"
          "x-systemd.mount-timeout=${failTimeout}"
        ];
      };
    }
  );
}
