{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.seafile;
  cfg = rootCfg.redis;
in
{
  imports = [ ./config.nix ];

  options.selfhosted.seafile.redis = {
    name = mkOption {
      type = types.str;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/redis:7";
      environmentFiles = [ config.sops.templates."seafile-redis.env".path ];
      cmd = [ "/bin/sh" "-c" "exec redis-server --requirepass \"$REDIS_PASSWORD\"" ];
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
    };
  };
}
