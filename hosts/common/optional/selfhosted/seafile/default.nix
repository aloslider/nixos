{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.seafile;
in
{
  imports = [
    ./mariadb
    ./notification
    ./redis
    ./seadoc
    ./server
  ];

  options.selfhosted.seafile = {
    targetName = mkOption {
      type = types.str;
    };
  };

  config = {
    systemd.targets."${common.backend}-${cfg.targetName}" = {
      unitConfig = {
        Description = "Root target for ${cfg.targetName}";
      };
      after = [ "${common.backend}-network-${common.network.name}.service" ];
      requires = [ "${common.backend}-network-${common.network.name}.service" ];
      partOf = [ "${common.backend}-${common.rootTarget.name}.target" ];
      wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
    };
  };
}
