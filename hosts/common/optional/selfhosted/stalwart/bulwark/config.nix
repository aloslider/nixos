{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.mail;
  domain = config.sops.placeholder."domains/serv";
  sessionSecret = config.sops.placeholder."bulwark/session_secret";
in
{
  config = mkIf rootCfg.enable {
    sops.templates."bulwark.env".content = ''
      HOSTNAME=0.0.0.0
      PORT=3000
      APP_NAME=Mail
     
      STALWART_FEATURES=true
      BULWARK_TELEMETRY=off
      SETTINGS_SYNC_ENABLED=true
      JMAP_SERVER_URL=https://${rootCfg.stalwart.subdomain}.${domain}
      ADMIN_PASSWORD=${config.sops.placeholder."bulwark/admin_password"}
      SESSION_SECRET=${sessionSecret}
      COOKIE_SAME_SITE=none
      ALLOWED_FRAME_ANCESTORS=https://${rootCfg.stalwart.subdomain}.${domain}
      NEXT_PUBLIC_PARENT_ORIGIN=https://${rootCfg.stalwart.subdomain}.${domain}

      OAUTH_ENABLED=true
      OAUTH_ONLY=true
      AUTO_SSO_ENABLED=true
      OAUTH_ISSUER_URL=https://${config.selfhosted.pocket-id.subdomain}.${domain}
      OAUTH_CLIENT_ID=bulwark
      OAUTH_SCOPES=openid email profile
      OAUTH_ALLOW_PRIVATE_ENDPOINTS=true
    '';
  };
}
