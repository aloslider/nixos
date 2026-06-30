{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.seafile;
  hostDataPath = "${common.dataDir}/seafile";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.seafile.mariadb = {
    name = mkOption {
      type = types.str;
    };
  };

  config = {
    virtualisation.oci-containers.containers.${cfg.mariadb.name} = {
      image = "docker.io/mariadb:10.11";
      environmentFiles = [ config.sops.templates."seafile-db.env".path ];
      volumes = [
        "${hostDataPath}/mysql:/var/lib/mysql"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
        "--health-cmd=/usr/local/bin/healthcheck.sh --connect --mariadbupgrade --innodb_initialized"
        "--health-interval=20s"
        "--health-start-period=30s"
        "--health-timeout=5s"
        "--health-retries=10"
      ];
    };

    systemd.services."${common.backend}-${cfg.mariadb.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [ "${common.backend}-network-${common.network.name}.service" ];
      requires = [ "${common.backend}-network-${common.network.name}.service" ];
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/mysql
      '';
    };
  };
}
