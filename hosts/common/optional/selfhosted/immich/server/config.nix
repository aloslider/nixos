{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.immich;
in
{
  config = mkIf rootCfg.enable {
    sops.templates."immich.env".content = ''
      DB_PASSWORD=${config.sops.placeholder."immich/db_password"}
    '';
  };
}
