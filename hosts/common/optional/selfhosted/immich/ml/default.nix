{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.immich;
  hostDataPath = "${common.dataDir}/immich";
in
{
  options.selfhosted.immich.ml = {
    name = mkOption {
      type = types.str;
    };
  };

  config = {
    virtualisation.oci-containers.containers."${cfg.ml.name}" = {
      image = "ghcr.io/immich-app/immich-machine-learning:${cfg.version}";
      environment = {
        IMMICH_VERSION = cfg.version;
      };
      volumes = [
        "${hostDataPath}/cache:/cache"
      ];
      extraOptions = [
        "--network=${common.network.name}"
      ];
    };

    systemd.services."${common.backend}-${cfg.ml.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [ "${common.backend}-network-${common.network.name}.service" ];
      requires = [ "${common.backend}-network-${common.network.name}.service" ];
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/cache
      '';
    };
  };
}
