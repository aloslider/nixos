{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.immich;
in
{
  imports = [
    ./ml
    ./postgresql
    ./redis
    ./server
  ];

  options.selfhosted.immich = {
    enable = mkEnableOption "Enable ${cfg.targetName} root target";
    targetName = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
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
      partOf = [ "${common.backend}-${common.rootTarget.name}.target" ];
      after = [ "${common.backend}-${common.rootTarget.name}.target" ];
    };
  };
}
