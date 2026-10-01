{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.immich;
  cfg = rootCfg.ml;
  hostDataPath = "${common.dataDir}/immich";
  version = "v3.1.0";
in
{
  options.selfhosted.immich.ml = {
    name = mkOption {
      type = types.str;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "ghcr.io/immich-app/immich-machine-learning:${version}";
      environment = {
        IMMICH_VERSION = version;
      };
      volumes = [
        "${hostDataPath}/cache:/cache"
      ];
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
      requires = [ "${common.backend}-${rootCfg.server.name}.service" ];
      after = [ "${common.backend}-${rootCfg.server.name}.service" ];
      preStart = ''
        mkdir -p ${hostDataPath}/cache
      '';
    };
  };
}
