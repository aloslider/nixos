{ config, ... }:
let
  cfg = config.selfhosted.vaultwarden;
  poCfg = config.selfhosted.pocket-id;
  domain = config.sops.placeholder."domains/serv";
in
{
  sops.secrets = {
    "vaultwarden/client_id" = { };
    "vaultwarden/client_secret" = { };
  };

  sops.templates."vaultwarden.env".content = ''
    DOMAIN=https://${cfg.subdomain}.${domain}
    LOG_LEVEL=info,vaultwarden::sso=debug
    SIGNUPS_ALLOWED=false
    SSO_ENABLED=false
    SSO_DEBUG_TOKENS=true
    SSO_ONLY=false
    SSO_AUTHORITY=https://${poCfg.subdomain}.${domain}
    SSO_CLIENT_ID=${config.sops.placeholder."vaultwarden/client_id"}
    SSO_CLIENT_SECRET=${config.sops.placeholder."vaultwarden/client_secret"}
    SSO_AUTH_ONLY_NOT_SESSION=true
    SSO_PKCE=true
  '';
}
