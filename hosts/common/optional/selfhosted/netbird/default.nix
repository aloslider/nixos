{
  config,
  lib,
  pkgs,
  ...
}:
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
  ];

  options.selfhosted.netbird = {
    targetName = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
  };

  config = {
    sops.secrets = {
      "netbird/proxy/token" = { };
    };

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
