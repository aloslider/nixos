{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.seafile;
  hostDataPath = "${common.dataDir}/seafile";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.seafile.seadoc = {
    name = mkOption {
      type = types.str;
    };
    hostHttpPort = mkOption {
      type = types.port;
    };
  };

  config = {
    virtualisation.oci-containers.containers.${cfg.seadoc.name} = {
      image = "docker.io/seafileltd/sdoc-server:2.0-latest";
      ports = [
        "0.0.0.0:${toString cfg.seadoc.hostHttpPort}:80"
      ];
      volumes = [
        "${hostDataPath}/seadoc/shared:/shared"
      ];
      environmentFiles = [ config.sops.templates."seadoc.env".path ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
      ];
    };

    systemd.services."${common.backend}-${cfg.seadoc.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
        "${common.backend}-${cfg.mariadb.name}.service"
      ];
      requires = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
        "${common.backend}-${cfg.mariadb.name}.service"
      ];
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/seadoc/shared
      '';
    };
  };
}
