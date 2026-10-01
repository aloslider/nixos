{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.seafile;
in
{
  config = mkIf rootCfg.enable {
    sops.templates."seafile-thumbnail.env".content = ''
      TIME_ZONE=${config.time.timeZone}
      SEAFILE_MYSQL_DB_HOST=${rootCfg.mariadb.name}
      SEAFILE_MYSQL_DB_PORT=3306
      SEAFILE_MYSQL_DB_USER=seafile
      SEAFILE_MYSQL_DB_PASSWORD=${config.sops.placeholder."seafile/mysql_password"}
      SEAFILE_MYSQL_DB_CCNET_DB_NAME=ccnet_db
      SEAFILE_MYSQL_DB_SEAFILE_DB_NAME=seafile_db
      NON_ROOT=false
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      SEAFILE_LOG_TO_STDOUT=false
      SITE_ROOT=/
      INNER_SEAHUB_SERVICE_URL=http://${rootCfg.server.name}
      THUMBNAIL_IMAGE_ORIGINAL_SIZE_LIMIT=256
      SEAF_SERVER_STORAGE_TYPE=disk
    '';
  };
}
