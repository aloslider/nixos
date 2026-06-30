{ config, ... }:
let
  cfg = config.selfhosted.homarr;
  poCfg = config.selfhosted.pocket-id;
  oidpDomain = "https://${poCfg.subdomain}.${config.sops.placeholder."domains/serv"}";
in
{
  sops.secrets = {
    "homarr/enc_key" = { };
    "homarr/client_id" = { };
    "homarr/client_secret" = { };
    "homarr/nextauth_secret" = { };
  };

  sops.templates."homarr.env" = {
    content = ''
      SECRET_ENCRYPTION_KEY=${config.sops.placeholder."homarr/enc_key"}
      NEXTAUTH_SECRET=${config.sops.placeholder."homarr/nextauth_secret"}
      AUTH_PROVIDERS=oidc
      AUTH_OIDC_CLIENT_ID=${config.sops.placeholder."homarr/client_id"}
      AUTH_OIDC_CLIENT_SECRET=${config.sops.placeholder."homarr/client_secret"}
      AUTH_OIDC_ISSUER=${oidpDomain}
      AUTH_OIDC_CLIENT_NAME="Pocket ID"
      AUTH_OIDC_SCOPE_OVERWRITE=openid email profile groups
      AUTH_OIDC_GROUPS_ATTRIBUTE=groups
      AUTH_LOGOUT_REDIRECT_URL=${oidpDomain}
      AUTH_OIDC_AUTO_LOGIN=true
    '';
  };
}
