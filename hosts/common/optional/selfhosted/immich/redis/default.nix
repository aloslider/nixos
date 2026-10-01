{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.immich;
  cfg = rootCfg.redis;
in
{
  options.selfhosted.immich.redis = {
    name = mkOption {
      type = types.str;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "docker.io/valkey/valkey:9@sha256:4963247afc4cd33c7d3b2d2816b9f7f8eeebab148d29056c2ca4d7cbc966f2d9";
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
        "--health-cmd=redis-cli ping || exit 1"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
    };
  };
}
