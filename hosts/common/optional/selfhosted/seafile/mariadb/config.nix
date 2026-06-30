{ config, ... }:
{
  sops.secrets = {
    "seafile/mysql_password" = { };
  };

  sops.templates."seafile-db.env".content = ''
    MYSQL_ROOT_PASSWORD=${config.sops.placeholder."seafile/mysql_password"}
    MYSQL_LOG_CONSOLE=true
    MARIADB_AUTO_UPGRADE=1
  '';
}
