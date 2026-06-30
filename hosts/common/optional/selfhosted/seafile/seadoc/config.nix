{ config, ... }:
let
  cfg = config.selfhosted.seafile;
in
{
  sops.templates."seadoc.env".content = ''
    DB_HOST=${cfg.mariadb.name}
    DB_PORT=3306
    DB_USER=seafile
    DB_PASSWORD=${config.sops.placeholder."seafile/mysql_password"}
    DB_NAME=seahub_db
    TIME_ZONE=${config.time.timeZone}
    JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
    NON_ROOT=false
    SEAHUB_SERVICE_URL=http://${cfg.server.name}
  '';
}
