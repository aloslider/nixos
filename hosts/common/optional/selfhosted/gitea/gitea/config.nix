{ config, ... }:
let 
  common = config.selfhosted.common;
  cfg = config.selfhosted.gitea;
  giteaDomain = "${cfg.gitea.subdomain}.${config.sops.placeholder."domains/serv"}";
in
{
  sops.templates."gitea.env".content = ''
    USER_UID=${common.user.uid}
    USER_GID=${common.group.gid}

    GITEA__database__DB_TYPE=postgres
    GITEA__database__HOST=${cfg.postgresql.name}:5432
    GITEA__database__NAME=gitea
    GITEA__database__USER=gitea
    GITEA__database__PASSWD=${config.sops.placeholder."gitea/db_password"}

    TZ=Europe/Moscow
    GITEA__time__DEFAULT_UI_LOCATION=Europe/Moscow

    GITEA__server__DOMAIN=${giteaDomain}
    GITEA__server__ROOT_URL=https://${giteaDomain}/
    GITEA__server__HTTP_PORT=3000
    GITEA__service__ALLOW_ONLY_EXTERNAL_REGISTRATION=false
    GITEA__service__DISABLE_REGISTRATION=true
    GITEA__service__SHOW_REGISTRATION_BUTTON=false
    GITEA__service__ENABLE_BASIC_AUTHENTICATION=false

    GITEA__service__ENABLE_PASSKEY_AUTHENTICATION=false
    GITEA__server__START_SSH_SERVER=true
    GITEA__server__SSH_DOMAIN=git.${config.sops.placeholder."domains/serv"}
    GITEA__server__SSH_LISTEN_HOST=0.0.0.0
    GITEA__server__SSH_LISTEN_PORT=2222
    GITEA__server__SSH_PORT=2222

    GITEA__security__INSTALL_LOCK=true

    GITEA__repository__MAX_CREATION_LIMIT=50

    GITEA__server__ENABLE_PASSWORD_SIGNIN_FORM=false
    GITEA__server__ENABLE_BASIC_AUTHENTICATION=false
    GITEA__openid__ENABLE_OPENID_SIGNIN=false
    GITEA__openid__ENABLE_OPENID_SIGNUP=false

    GITEA__oauth2_client__ENABLE_AUTO_REGISTRATION=true
    GITEA__oauth2_client__ACCOUNT_LINKING=auto
    GITEA__oauth2_client__USERNAME=preferred_username

    GITEA__session__COOKIE_SECURE=true
    GITEA__log__LEVEL=Info
  '';
}

