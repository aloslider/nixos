{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.gitea;
  cfg = rootCfg.postgresql;
  hostDataPath = "${common.dataDir}/gitea";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.gitea.postgresql = {
    name = mkOption {
      type = types.str;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "postgres:16";
      environmentFiles = [ config.sops.templates."gitea-db.env".path ];
      volumes = [
        "${hostDataPath}/dbData:/var/lib/postgresql/data"
      ];
      extraOptions = [
        "--network=${common.network.name}"
        "--network-alias=${cfg.name}"
        "--health-cmd=pg_isready -U gitea"
        "--health-interval=10s"
        "--health-timeout=5s"
        "--health-retries=5"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/dbData
        chown 70:70 ${hostDataPath}/dbData
      '';
    };
  };
}
