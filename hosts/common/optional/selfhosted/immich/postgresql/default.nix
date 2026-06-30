{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.immich;
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

  config = {
    virtualisation.oci-containers.containers."${cfg.postgresql.name}" = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      environmentFiles = [ config.sops.templates."immich-db.env".path ];
      environment = {
        POSTGRES_DB = cfg.postgresql.db;
        POSTGRES_USER = cfg.postgresql.user;
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

    systemd.services."${common.backend}-${cfg.postgresql.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [ "${common.backend}-network-${common.network.name}.service" ];
      requires = [ "${common.backend}-network-${common.network.name}.service" ];
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/db
      '';
    };
  };
}
