{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.seafile;
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

  config = {
    virtualisation.oci-containers.containers.${cfg.server.name} = {
      image = "docker.io/seafileltd/seafile-mc:13.0-latest";
      ports = [
        "0.0.0.0:${toString cfg.server.hostHttpPort}:80"
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

    systemd.services."${common.backend}-${cfg.server.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
        "${common.backend}-${config.selfhosted.seafile.mariadb.name}.service"
        "${common.backend}-${config.selfhosted.seafile.redis.name}.service"
      ];
      requires = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
        "${common.backend}-${cfg.mariadb.name}.service"
        "${common.backend}-${cfg.redis.name}.service"
      ];
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
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
