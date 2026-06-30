{ config, ... }:
let
  fullDomain = "${config.selfhosted.netbird.subdomain}.${config.sops.placeholder."domains/serv"}";
in
{
  sops.templates."nb-dashboard.env".content = ''
    NETBIRD_MGMT_API_ENDPOINT=https://${fullDomain}
    NETBIRD_MGMT_GRPC_API_ENDPOINT=https://${fullDomain}

    # Initial NB setup: custom OIDCP is added manually in panel later
    AUTH_AUTHORITY=https://${fullDomain}/oauth2
    AUTH_AUDIENCE=netbird-dashboard
    AUTH_CLIENT_ID=netbird-dashboard
    AUTH_CLIENT_SECRET=
    USE_AUTH0=false
    AUTH_SUPPORTED_SCOPES=openid profile email groups
    AUTH_REDIRECT_URI=/nb-auth
    AUTH_SILENT_REDIRECT_URI=/nb-silent-auth

    LETSENCRYPT_DOMAIN=none
    LETSENCRYPT_EMAIL=${config.sops.placeholder."letsEncrypt/email"}
  '';
}
