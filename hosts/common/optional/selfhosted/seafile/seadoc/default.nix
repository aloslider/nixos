{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.seafile;
  cfg = rootCfg.seadoc;
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

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/seafileltd/sdoc-server:2.0-latest";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:80"
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

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      requires = [ "${common.backend}-${rootCfg.mariadb.name}.service" ];
      after = [ "${common.backend}-${rootCfg.mariadb.name}.service" ];
      preStart = ''
        mkdir -p ${hostDataPath}/seadoc/shared
      '';
    };
  };
}
