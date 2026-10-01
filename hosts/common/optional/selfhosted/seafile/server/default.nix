{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.seafile;
  cfg = rootCfg.server;
  hostDataPath = "${common.dataDir}/seafile";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.seafile.server = {
    name = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
    hostHttpPort = mkOption {
      type = types.port;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/seafileltd/seafile-mc:13.0-latest";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:80"
      ];
      environmentFiles = [ config.sops.templates."seafile.env".path ];
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
        "${common.backend}-${rootCfg.redis.name}.service"
      ];
      after = [
        "${common.backend}-${rootCfg.mariadb.name}.service"
        "${common.backend}-${rootCfg.redis.name}.service"
      ];
      preStart = ''
        mkdir -p ${hostDataPath}/server/shared/seafile/conf

        cp -f ${config.sops.templates."seahub_settings.py".path} \
              ${hostDataPath}/server/shared/seafile/conf/seahub_settings.py
        cp -f ${config.sops.templates."seafdav.conf".path} \
              ${hostDataPath}/server/shared/seafile/conf/seafdav.conf
        cp -f ${config.sops.templates."seafile.conf".path} \
              ${hostDataPath}/server/shared/seafile/conf/seafile.conf
        chmod 644 ${hostDataPath}/server/shared/seafile/conf/{seafile.conf,seafdav.conf,seahub_settings.py}
      '';
    };
  };
}
