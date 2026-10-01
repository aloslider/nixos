{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.mirotalk;
  cfg = rootCfg.server;
  domain = "${config.sops.placeholder."domains/serv"}";
  pocketIdSubdomain = config.selfhosted.pocket-id.subdomain;
  publicUrl = "https://${cfg.subdomain}.${domain}";
  stunUrl = "stun:${config.selfhosted.netbird.subdomain}.${domain}:3478";
in
{
  config = mkIf rootCfg.enable {
    sops.templates."mirotalk.env".content = ''
      NODE_ENV=production
      TZ=${config.time.timeZone}
      PORT=3000
      TRUST_PROXY=true

      OIDC_ENABLED=true
      OIDC_ALLOW_ROOMS_CREATION_FOR_AUTH_USERS=true
      OIDC_BASE_URL_DYNAMIC=false
      OIDC_ISSUER_BASE_URL=https://${pocketIdSubdomain}.${domain}
      OIDC_BASE_URL=${publicUrl}
      OIDC_CLIENT_ID=mirotalk
      OIDC_CLIENT_SECRET=${config.sops.placeholder."mirotalk/client_secret"}
      OIDC_AUTH_REQUIRED=false
      OIDC_AUTH_LOGOUT=true
      SESSION_SECRET=${config.sops.placeholder."mirotalk/session_secret"}

      HOST_PROTECTED=true
      HOST_USER_AUTH=false
      HOST_USERS='[]'

      API_KEY_SECRET=${config.sops.placeholder."mirotalk/api_key_secret"}

      STUN_SERVER_ENABLED=true
      STUN_SERVER_URL=${stunUrl}
      TURN_SERVER_ENABLED=false

      STATS_ENABLED=false
      SURVEY_ENABLED=false
    '';
  };
}
