{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.immich;
in
{
  config = mkIf rootCfg.enable {
    sops.templates."immich-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."immich/db_password"}
    '';
  };
}
