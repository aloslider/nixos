{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.seafile;
in
{
  config = mkIf rootCfg.enable {
    sops.templates."seafile-redis.env".content = ''
      REDIS_PASSWORD=${config.sops.placeholder."seafile/redis_password"}
    '';
  };
}
