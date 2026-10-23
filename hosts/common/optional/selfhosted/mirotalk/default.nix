{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.mirotalk;
in
{
  imports = [ ./server ];

  options.selfhosted.mirotalk = {
    enable = mkEnableOption "Enable ${cfg.targetName} root target";
    targetName = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "mirotalk/client_secret" = { };
      "mirotalk/session_secret" = { };
      "mirotalk/api_key_secret" = { };
      "mirotalk/jwt_secret" = { };
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
