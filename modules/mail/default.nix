{
  config,
  lib,
  ...
}: let
  cfg = config.psa.mail;
in {
  options = {
    psa.mail.enable = lib.mkEnableOption "Mailserver";
  };

  config = lib.mkIf cfg.enable {
    services.postfix = {
      enable = true;
      domain = "psa-team06.cit.tum.de";

      # Enable header checks
      enableHeaderChecks = true;
      headerChecks = [
        {
          pattern = "/^From:(.*)@.+?\\.psa-team(\\d+)\\.cit\\.tum\\.de$/";
          action = "REDIRECT ''${1}@psa-team''${2}.cit.tum.de";
        }
      ];
    };
  };
}
