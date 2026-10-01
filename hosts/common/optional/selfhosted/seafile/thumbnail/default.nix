{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.seafile;
  cfg = rootCfg.thumbnail;
  hostDataPath = "${common.dataDir}/seafile";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.seafile.thumbnail = {
    name = mkOption {
      type = types.str;
    };
    hostHttpPort = mkOption {
      type = types.port;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/seafileltd/thumbnail-server:13.0.20";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:80"
      ];
      environmentFiles = [ config.sops.templates."seafile-thumbnail.env".path ];
      volumes = [
        "${hostDataPath}/server/shared:/shared"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      requires = [
        "${common.backend}-${rootCfg.mariadb.name}.service"
        "${common.backend}-${rootCfg.server.name}.service"
      ];
      after = [
        "${common.backend}-${rootCfg.mariadb.name}.service"
        "${common.backend}-${rootCfg.server.name}.service"
      ];
    };
  };
}
