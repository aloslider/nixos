{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.immich;
in
{
  imports = [
    ./immich
    ./ml
    ./postgresql
    ./redis
  ];

  options.selfhosted.immich = {
    targetName = mkOption {
      type = types.str;
    };
    version = mkOption {
      type = types.str;
    };
  };

  config = {
    sops.secrets = {
      "immich/db_password" = { };
      "immich/client_id" = { };
      "immich/client_secret" = { };
    };

    systemd.targets."${common.backend}-${cfg.targetName}" = {
      unitConfig = {
        Description = "Root target for ${cfg.targetName}";
      };
      wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
    };
  };
}
