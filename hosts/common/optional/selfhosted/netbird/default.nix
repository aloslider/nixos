{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.netbird;
in
{
  imports = [
    ./dashboard
    ./proxy
    ./server
    ./traefik
  ];

  options.selfhosted.netbird = {
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
      "domains/serv" = { };
      "letsEncrypt/email" = { };
      "netbird/proxy/token" = { };
      "netbird/server/auth_secret" = { };
      "netbird/server/enc_key" = { };
    };

    systemd.targets."${common.backend}-${cfg.targetName}" = {
      unitConfig = {
        Description = "Root target for ${cfg.targetName}";
      };
      wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
      partOf = [ "${common.backend}-${common.rootTarget.name}.target" ];
      after = [ "${common.backend}-network-${common.rootTarget.name}.service" ];
    };
  };
}
