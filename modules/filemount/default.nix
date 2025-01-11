{ config, ... }:
let
  timeout = 60; # 60 seconds
  
  userPaths = [
    { username = "ge95vir"; path = "fileserver.psa-team01.cit.tum.de:/raid/psaraid/userdata/home/ge95vir"; }
    # { username = "ge43fim"; path = "fileserver.psa-team09.cit.tum.de:"; }
    # { username = "ge96hoj"; path = "fileserver.psa-team02.cit.tum.de:"; }
    # { username = "ge78zig"; path = "fileserver.psa-team03.cit.tum.de:"; }
    # { username = "ge84fag"; path = "fileserver.psa-team03.cit.tum.de:"; }
    # { username = "ge78nes"; path = "fileserver.psa-team02.cit.tum.de:"; }
    # { username = "ge87yen"; path = "fileserver.psa-team04.cit.tum.de:"; }
    # { username = "ge47sof"; path = "fileserver.psa-team04.cit.tum.de:"; }
    { username = "ge47kut"; path = "fileserver.psa-team05.cit.tum.de:/ge47kut"; }
    { username = "ge87liq"; path = "fileserver.psa-team05.cit.tum.de:/ge87liq"; }
    { username = "ge59pib"; path = "fileserver.psa-team06.cit.tum.de:/mnt/raid/userdata/home/ge59pib"; }
    { username = "ge65peq"; path = "fileserver.psa-team06.cit.tum.de:/mnt/raid/userdata/home/ge65peq"; }
    # { username = "ge63gut"; path = "fileserver.psa-team07.cit.tum.de:"; }
    # { username = "ge64baw"; path = "fileserver.psa-team07.cit.tum.de:"; }
    { username = "ge84zoj"; path = "fileserver.psa-team08.cit.tum.de:/storage/userdata/home/ge84zoj"; }
    { username = "ge94bob"; path = "fileserver.psa-team08.cit.tum.de:/storage/userdata/home/ge94bob"; }
    { username = "ge87huk"; path = "fileserver.psa-team01.cit.tum.de:/raid/psaraid/userdata/home/ge87huk"; }
    # { username = "ge64wug"; path = "fileserver.psa-team09.cit.tum.de:"; }
    # { username = "ge65hog"; path = "fileserver.psa-team10.cit.tum.de:"; }
    # { username = "ge38hoy"; path = "fileserver.psa-team10.cit.tum.de:"; }
  ];

  forEachUserPath = f: builtins.listToAttrs (map f userPaths);
in
{
  fileSystems = forEachUserPath (e:
    {
      name = "/home/${e.username}";
      value = {
        device = e.path;
        fsType = "nfs";
        options = [
          "x-systemd.automount"
          "noauto"
          "x-systemd.idle-timeout=${toString timeout}"
        ];
      };
    }
  );
}
