{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.seafile;
in
{
  imports = [ ./config.nix ];

  options.selfhosted.seafile.redis = {
    name = mkOption {
      type = types.str;
    };
  };

  config = {
    virtualisation.oci-containers.containers.${cfg.redis.name} = {
      image = "docker.io/redis:7";
      environmentFiles = [ config.sops.templates."seafile-redis.env".path ];
      cmd = [ "/bin/sh" "-c" "exec redis-server --requirepass \"$REDIS_PASSWORD\"" ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
      ];
    };

    systemd.services."${common.backend}-${cfg.redis.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [ "${common.backend}-network-${common.network.name}.service" ];
      requires = [ "${common.backend}-network-${common.network.name}.service" ];
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
    };
  };
}
