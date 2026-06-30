{ config, ... }:
{
  sops.secrets = {
    "seafile/redis_password" = { };
  };

  sops.templates."seafile-redis.env".content = ''
    REDIS_PASSWORD=${config.sops.placeholder."seafile/redis_password"}
  '';
}
