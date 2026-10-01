{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.homarr;
in
{
  imports = [ ./server ];

  options.selfhosted.homarr = {
    enable = mkEnableOption "Enable ${cfg.targetName} root target";
    targetName = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "homarr/enc_key" = { };
      "homarr/client_id" = { };
      "homarr/client_secret" = { };
      "homarr/nextauth_secret" = { };
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
