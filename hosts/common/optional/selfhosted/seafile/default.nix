{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.seafile;
in
{
  imports = [
    ./collabora
    ./mariadb
    ./notification
    ./redis
    ./seadoc
    ./server
    ./thumbnail
  ];

  options.selfhosted.seafile = {
    enable = mkEnableOption "Enable ${cfg.targetName} root target";
    targetName = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "seafile/admin_email" = { };
      "seafile/admin_password" = { };
      "seafile/client_id" = { };
      "seafile/client_secret" = { };
      "seafile/jwt_private_key" = { };
      "seafile/mysql_password" = { };
      "seafile/redis_password" = { };
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
