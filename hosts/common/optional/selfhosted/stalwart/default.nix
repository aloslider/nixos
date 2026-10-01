{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.mail;
in
{
  imports = [
    ./bulwark
    ./stalwart
  ];

  options.selfhosted.mail = {
    enable = mkEnableOption "Enable ${cfg.targetName} root target";
    targetName = mkOption {
      type = types.str;
    };
    hostPorts = mkOption {
      type = types.listOf types.port;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "bulwark/admin_password" = { };
      "bulwark/session_secret" = { };
      "domains/serv" = { };
      "letsEncrypt/email" = { };
      "porkbun/serv/api_key" = { };
      "porkbun/serv/secret_key" = { };
      "stalwart/admin_password" = { };
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
