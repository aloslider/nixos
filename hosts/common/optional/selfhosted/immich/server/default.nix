{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.immich;
  cfg = rootCfg.server;
  hostDataPath = "${common.dataDir}/immich";
  version = "v3.1.0";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.immich.server = {
    name = mkOption {
      type = types.str;
    };
    hostHttpPort = mkOption {
      type = types.port;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "ghcr.io/immich-app/immich-server:${version}";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:2283"
      ];
      environmentFiles = [ config.sops.templates."immich.env".path ];
      environment = {
        IMMICH_VERSION = version;
        DB_HOSTNAME = rootCfg.postgresql.name;
        DB_DATABASE_NAME = rootCfg.postgresql.db;
        DB_USERNAME = rootCfg.postgresql.user;
        REDIS_HOSTNAME = rootCfg.redis.name;
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

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      requires = [
        "${common.backend}-${rootCfg.postgresql.name}.service"
        "${common.backend}-${rootCfg.redis.name}.service"
      ];
      after = [
        "${common.backend}-${rootCfg.postgresql.name}.service"
        "${common.backend}-${rootCfg.redis.name}.service"
      ];
      preStart = ''
        mkdir -p ${hostDataPath}/data
      '';
    };
  };
}
