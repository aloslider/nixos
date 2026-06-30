{ config, ... }:
{
  sops.templates."immich-db.env".content = ''
    POSTGRES_PASSWORD=${config.sops.placeholder."immich/db_password"}
  '';
}
