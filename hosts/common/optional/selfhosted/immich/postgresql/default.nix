{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.immich;
  cfg = rootCfg.postgresql;
  hostDataPath = "${common.dataDir}/immich";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.immich.postgresql = {
    name = mkOption {
      type = types.str;
    };
    db = mkOption {
      type = types.str;
    };
    user = mkOption {
      type = types.str;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      environmentFiles = [ config.sops.templates."immich-db.env".path ];
      environment = {
        POSTGRES_DB = cfg.db;
        POSTGRES_USER = cfg.user;
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      volumes = [
        "${hostDataPath}/db:/var/lib/postgresql/data"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
        "--shm-size=128m"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/db
      '';
    };
  };
}
