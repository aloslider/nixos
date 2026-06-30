{ config, ... }:
let
  cfg = config.selfhosted;
  domain = "${config.sops.placeholder."domains/serv"}";
in
{
  sops.secrets = {
    "vaultwarden/admin_token" = { };
    "vaultwarden/client_id" = { };
    "vaultwarden/client_secret" = { };
  };

  sops.templates."vaultwarden.env".content = ''
    DOMAIN=https://${cfg.vaultwarden.subdomain}.${domain}
    SIGNUPS_ALLOWED=false
    ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin_token"}

    # SSO
    SSO_ENABLED=true
    SSO_ONLY=false
    SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION=true
    SSO_AUTHORITY=https://${cfg.pocket-id.subdomain}.${domain}
    SSO_CLIENT_ID=${config.sops.placeholder."vaultwarden/client_id"}
    SSO_CLIENT_SECRET=${config.sops.placeholder."vaultwarden/client_secret"}
    SSO_AUTH_ONLY_NOT_SESSION=true
  '';
}
