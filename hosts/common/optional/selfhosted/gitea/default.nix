{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.gitea;
in
{
  imports = [
    ./postgresql
    ./server
  ];

  options.selfhosted.gitea = {
    enable = mkEnableOption "Enable ${cfg.targetName} root target";
    targetName = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "gitea/db_password" = { };
      "gitea/client_id" = { };
      "gitea/client_secret" = { };
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
