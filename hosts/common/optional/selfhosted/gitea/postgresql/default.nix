{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.gitea;
  hostDataPath = "${common.dataDir}/gitea";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.gitea.postgresql = {
    name = mkOption {
      type = types.str;
    };
  };

  config = {
    virtualisation.oci-containers.containers."${cfg.postgresql.name}" = {
      image = "postgres:16";
      environmentFiles = [ config.sops.templates."gitea-db.env".path ];
      volumes = [
        "${hostDataPath}/dbData:/var/lib/postgresql/data"
      ];
      extraOptions = [
        "--network=${common.network.name}"
        "--network-alias=${cfg.postgresql.name}"
        "--health-cmd=pg_isready -U gitea"
        "--health-interval=10s"
        "--health-timeout=5s"
        "--health-retries=5"
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
        mkdir -p ${hostDataPath}/dbData
        chown 70:70 ${hostDataPath}/dbData
      '';
    };
  };
}
