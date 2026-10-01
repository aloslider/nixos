{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.seafile;
  poCfg = config.selfhosted.pocket-id;
  domain = config.sops.placeholder."domains/serv";
in
{
  config = mkIf rootCfg.enable {
    sops.templates."seafile.env".content = ''
      SEAFILE_MYSQL_DB_HOST=${rootCfg.mariadb.name}
      SEAFILE_MYSQL_DB_PORT=3306
      SEAFILE_MYSQL_DB_USER=seafile
      SEAFILE_MYSQL_DB_PASSWORD=${config.sops.placeholder."seafile/mysql_password"}
      SEAFILE_MYSQL_DB_CCNET_DB_NAME=ccnet_db
      SEAFILE_MYSQL_DB_SEAFILE_DB_NAME=seafile_db
      SEAFILE_MYSQL_DB_SEAHUB_DB_NAME=seahub_db
      TIME_ZONE=${config.time.timeZone}
      INIT_SEAFILE_MYSQL_ROOT_PASSWORD=${config.sops.placeholder."seafile/mysql_password"}
      INIT_SEAFILE_ADMIN_EMAIL=${config.sops.placeholder."seafile/admin_email"}
      INIT_SEAFILE_ADMIN_PASSWORD=${config.sops.placeholder."seafile/admin_password"}
      SEAFILE_SERVER_HOSTNAME=${rootCfg.server.subdomain}.${domain}
      SEAFILE_SERVER_PROTOCOL=https
      SEAFILE_SERVER_LETSENCRYPT=false
      SITE_ROOT=/
      NON_ROOT=false
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt_private_key"}
      SEAFILE_LOG_TO_STDOUT=false
      ENABLE_GO_FILESERVER=true
      CACHE_PROVIDER=redis
      REDIS_HOST=${rootCfg.redis.name}
      REDIS_PORT=6379
      REDIS_PASSWORD=${config.sops.placeholder."seafile/redis_password"}
      ENABLE_NOTIFICATION_SERVER=true
      INNER_NOTIFICATION_SERVER_URL=http://${rootCfg.notification.name}:8083
      NOTIFICATION_SERVER_URL=https://${rootCfg.server.subdomain}.${domain}/notification
      ENABLE_SEAFILE_AI=false
      MD_FILE_COUNT_LIMIT=100000
    '';

    sops.templates."seahub_settings.py".content = ''
      ENABLE_VIDEO_THUMBNAIL = True
      SERVICE_URL = "https://${rootCfg.server.subdomain}.${domain}"
      FILE_SERVER_ROOT = "https://${rootCfg.server.subdomain}.${domain}/seafhttp"
      ENABLE_OAUTH = True 
      OAUTH_CREATE_UNKNOWN_USER = True
      OAUTH_ACTIVATE_USER_AFTER_CREATION = True
      OAUTH_ENABLE_INSECURE_TRANSPORT = False
      OAUTH_CLIENT_ID = "${config.sops.placeholder."seafile/client_id"}"
      OAUTH_CLIENT_SECRET = "${config.sops.placeholder."seafile/client_secret"}" 
      OAUTH_REDIRECT_URL = "https://${rootCfg.server.subdomain}.${domain}/oauth/callback"
      OAUTH_PROVIDER = "pocket-id"
      OAUTH_PROVIDER_DOMAIN = "pocket-id"
      OAUTH_AUTHORIZATION_URL = "https://${poCfg.subdomain}.${domain}/authorize"
      OAUTH_TOKEN_URL = "https://${poCfg.subdomain}.${domain}/api/oidc/token"
      OAUTH_USER_INFO_URL = "https://${poCfg.subdomain}.${domain}/api/oidc/userinfo"
      OAUTH_SCOPE = [
        "openid",
        "profile",
        "email"
      ]
      OAUTH_ATTRIBUTE_MAP = {
        "sub": (True, "uid"),
        "name": (False, "name"),
        "email": (False, "contact_email"),
      }
      CLIENT_SSO_VIA_LOCAL_BROWSER = True

      ENABLE_SEADOC = True
      SEADOC_SERVER_URL = "https://${rootCfg.server.subdomain}.${domain}/sdoc-server"

      OFFICE_SERVER_TYPE = "CollaboraOffice"
      ENABLE_OFFICE_WEB_APP = True
      OFFICE_WEB_APP_BASE_URL = "http://${rootCfg.collabora.name}:9980/hosting/discovery"
      WOPI_ACCESS_TOKEN_EXPIRATION = 10 * 60 * 60
      OFFICE_WEB_APP_FILE_EXTENSION = (
        "odp", "ods", "odt",
        "xls", "xlsb", "xlsm", "xlsx",
        "ppsx", "ppt", "pptm", "pptx",
        "doc", "docm", "docx",
      )
      ENABLE_OFFICE_WEB_APP_EDIT = True
      OFFICE_WEB_APP_EDIT_FILE_EXTENSION = (
        "odp", "ods", "odt",
        "xls", "xlsb", "xlsm", "xlsx",
        "ppsx", "ppt", "pptm", "pptx",
        "doc", "docm", "docx",
      )

      ENABLE_WEBDAV_SECRET = True
      WEBDAV_SECRET_MIN_LENGTH = 8
      USE_X_FORWARDED_HOST = True
      SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
      ALLOWED_HOSTS = [ 
        ".${domain}" ,
        "127.0.0.1",
        "localhost",
        "${rootCfg.server.name}",
      ]
      CSRF_COOKIE_SECURE = True
      CSRF_COOKIE_SAMESITE = "Lax"
      CSRF_TRUSTED_ORIGINS = [
        "https://${rootCfg.server.subdomain}.${domain}"
      ]
    '';

    sops.templates."seafdav.conf".content = ''
      [WEBDAV]
      enabled = true
      port = 8080
      debug = true
      share_name = /seafdav
      workers = 5
      timeout = 1200
    '';

    sops.templates."seafile.conf".content = ''
      [quota]
      default = 100
    '';
  };
}
