{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.netbird;
  cfg = rootCfg.dashboard;
in
{
  imports = [ ./config.nix ];

  options.selfhosted.netbird.dashboard = {
    name = mkOption {
      type = types.str;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/netbirdio/dashboard:v2.95.0";
      environmentFiles = [ config.sops.templates."nb-dashboard.env".path ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=${cfg.name}"
        "--network=${common.network.name}"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      requires = [ "${common.backend}-${rootCfg.server.name}.service" ];
      after = [ "${common.backend}-${rootCfg.server.name}.service" ];
    };
  };
}
