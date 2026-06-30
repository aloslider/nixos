{ config, ... }:
{
  sops.templates."immich.env".content = ''
    DB_PASSWORD=${config.sops.placeholder."immich/db_password"}
  '';
}
