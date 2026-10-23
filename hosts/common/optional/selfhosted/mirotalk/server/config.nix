{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.mirotalk;
  cfg = rootCfg.server;
  domain = "${config.sops.placeholder."domains/serv"}";
  pocketIdSubdomain = config.selfhosted.pocket-id.subdomain;
  publicUrl = "https://${cfg.subdomain}.${domain}";
in
{
  config = mkIf rootCfg.enable {
    sops.templates."mirotalk.env".content = ''
      NODE_ENV=production
      TZ=${config.time.timeZone}
      SERVER_LISTEN_PORT=3010
      SERVER_HOST_URL=${publicUrl}
      TRUST_PROXY=true

      SFU_LISTEN_IP=0.0.0.0
      SFU_ANNOUNCED_IP=${config.sops.placeholder."turn/public-ip"}
      SFU_MIN_PORT=${toString cfg.minPort}
      SFU_MAX_PORT=${toString cfg.maxPort}
      SFU_NUM_WORKERS=4
      SFU_SERVER=false

      OIDC_ENABLED=true
      OIDC_ALLOW_ROOMS_CREATION_FOR_AUTH_USERS=true
      OIDC_BASE_URL_DYNAMIC=false
      OIDC_ISSUER=https://${pocketIdSubdomain}.${domain}
      OIDC_BASE_URL=${publicUrl}
      OIDC_CLIENT_ID=mirotalk
      OIDC_CLIENT_SECRET=${config.sops.placeholder."mirotalk/client_secret"}
      OIDC_SECRET=${config.sops.placeholder."mirotalk/session_secret"}
      OIDC_AUTH_REQUIRED=false
      OIDC_AUTH_LOGOUT=true

      JWT_SECRET=${config.sops.placeholder."mirotalk/jwt_secret"}
      JWT_EXPIRATION=1h

      API_KEY_SECRET=${config.sops.placeholder."mirotalk/api_key_secret"}

      SHOW_ACTIVE_ROOMS=true
    '';
  };
}
