{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.immich;
  cfgPath = "/config/immich.json";
  hostDataPath = "${common.dataDir}/immich";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.immich.immich = {
    name = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
    hostPort = mkOption {
      type = types.port;
    };
  };

  config = {
    virtualisation.oci-containers.containers."${cfg.immich.name}" = {
      image = "ghcr.io/immich-app/immich-server:${cfg.version}";
      ports = [
        "0.0.0.0:${toString cfg.immich.hostPort}:2283"
      ];
      environmentFiles = [ config.sops.templates."immich.env".path ];
      environment = {
        IMMICH_VERSION = cfg.version;
        DB_HOSTNAME = cfg.postgresql.name;
        DB_DATABASE_NAME = cfg.postgresql.db;
        DB_USERNAME = cfg.postgresql.user;
        REDIS_HOSTNAME = cfg.redis.name;
      };
      volumes = [
        "${hostDataPath}/data:/data"
        "/etc/localtime:/etc/localtime:ro"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
      ];
    };

    systemd.services."${common.backend}-${cfg.immich.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${cfg.postgresql.name}.service"
        "${common.backend}-${cfg.redis.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
      ];
      requires = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${cfg.postgresql.name}.service"
        "${common.backend}-${cfg.redis.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
      ];
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/data
      '';
    };
  };
}
