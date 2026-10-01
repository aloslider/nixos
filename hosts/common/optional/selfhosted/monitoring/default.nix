{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.monitoring;
in
{
  imports = [
    ./grafana
    ./node-exporter
    ./prometheus
  ];

  options.selfhosted.monitoring = {
    enable = mkEnableOption "Enable ${cfg.targetName} root target";
    targetName = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "grafana/admin_password" = { };
      "grafana/client_secret" = { };
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
