{ config, ... }:
let
  cfg = config.selfhosted.seafile;
in
{
  sops.templates."seafile-notification.env".content = ''
    SEAFILE_MYSQL_DB_HOST=${cfg.mariadb.name}
    SEAFILE_MYSQL_DB_PORT=3306
    SEAFILE_MYSQL_DB_USER=seafile
    SEAFILE_MYSQL_DB_PASSWORD=${config.sops.placeholder."seafile/mysql_password"}
    SEAFILE_MYSQL_DB_CCNET_DB_NAME=ccnet_db
    SEAFILE_MYSQL_DB_SEAFILE_DB_NAME=seafile_db
    JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
    SEAFILE_LOG_TO_STDOUT=false
    NOTIFICATION_SERVER_LOG_LEVEL=info
  '';
}
