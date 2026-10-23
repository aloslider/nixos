{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.vaultwarden;
  cfg = rootCfg.server;
  mailCfg = config.selfhosted.mail.stalwart;
  domain = "${config.sops.placeholder."domains/serv"}";
  pocketIdSubdomain = config.selfhosted.pocket-id.subdomain;
  smtpUser = "noreply@${domain}";
in
{
  config = mkIf rootCfg.enable {
    sops.templates."vaultwarden.env".content = ''
      DOMAIN=https://${cfg.subdomain}.${domain}
      SIGNUPS_ALLOWED=false
      ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin_token"}

      # SSO
      SSO_ENABLED=true
      SSO_ONLY=false
      SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION=true
      SSO_AUTHORITY=https://${pocketIdSubdomain}.${domain}
      SSO_CLIENT_ID=${config.sops.placeholder."vaultwarden/client_id"}
      SSO_CLIENT_SECRET=${config.sops.placeholder."vaultwarden/client_secret"}
      SSO_AUTH_ONLY_NOT_SESSION=true

      # SMTP
      SMTP_HOST=${mailCfg.subdomain}.${domain}
      SMTP_FROM=${smtpUser}
      SMTP_FROM_NAME=Vaultwarden
      SMTP_PORT=465
      SMTP_SECURITY=force_tls
      SMTP_USERNAME=${smtpUser}
      SMTP_PASSWORD=${config.sops.placeholder."vaultwarden/smtp_password"}
      SMTP_TIMEOUT=15
      SMTP_ACCEPT_INVALID_CERTS=false
      SMTP_ACCEPT_INVALID_HOSTNAMES=false
    '';
  };
}
