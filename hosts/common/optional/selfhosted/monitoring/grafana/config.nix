{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.monitoring;
  cfg = rootCfg.grafana;
  domain = config.sops.placeholder."domains/serv";
  grafanaDomain = "${cfg.subdomain}.${domain}";
  oidpDomain = "https://${config.selfhosted.pocket-id.subdomain}.${domain}";
in
{
  config = mkIf rootCfg.enable {
    sops.templates."grafana.env".content = ''
      GF_SERVER_DOMAIN=${grafanaDomain}
      GF_SERVER_ROOT_URL=https://${grafanaDomain}/
      GF_SERVER_HTTP_ADDR=0.0.0.0
      GF_SERVER_HTTP_PORT=3000
      GF_SECURITY_ADMIN_USER=admin
      GF_SECURITY_ADMIN_PASSWORD=${config.sops.placeholder."grafana/admin_password"}
      GF_SECURITY_COOKIE_SECURE=true
      GF_SECURITY_COOKIE_SAMESITE=lax
      GF_USERS_ALLOW_SIGN_UP=false
      GF_USERS_AUTO_ASSIGN_ORG=true
      GF_ANALYTICS_REPORTING_ENABLED=false
      GF_ANALYTICS_CHECK_FOR_UPDATES=false
      GF_AUTH_DISABLE_LOGIN_FORM=true
      GF_AUTH_SIGNOUT_REDIRECT_URL=${oidpDomain}
      GF_AUTH_GENERIC_OAUTH_ENABLED=true
      GF_AUTH_GENERIC_OAUTH_NAME="Pocket ID"
      GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP=true
      GF_AUTH_GENERIC_OAUTH_AUTO_LOGIN=true
      GF_AUTH_GENERIC_OAUTH_CLIENT_ID=grafana
      GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=${config.sops.placeholder."grafana/client_secret"}
      GF_AUTH_GENERIC_OAUTH_SCOPES=openid email profile groups
      GF_AUTH_GENERIC_OAUTH_AUTH_URL=${oidpDomain}/authorize
      GF_AUTH_GENERIC_OAUTH_TOKEN_URL=${oidpDomain}/api/oidc/token
      GF_AUTH_GENERIC_OAUTH_API_URL=${oidpDomain}/api/oidc/userinfo
      GF_AUTH_GENERIC_OAUTH_USE_PKCE=true
      GF_AUTH_GENERIC_OAUTH_USE_REFRESH_TOKEN=true
      GF_AUTH_GENERIC_OAUTH_EMAIL_ATTRIBUTE_PATH=email
      GF_AUTH_GENERIC_OAUTH_LOGIN_ATTRIBUTE_PATH=preferred_username
      GF_AUTH_GENERIC_OAUTH_NAME_ATTRIBUTE_PATH=name
      GF_AUTH_GENERIC_OAUTH_GROUPS_ATTRIBUTE_PATH=groups
      GF_AUTH_GENERIC_OAUTH_ALLOW_ASSIGN_GRAFANA_ADMIN=true
      GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH=contains(groups[*], 'admin') && 'GrafanaAdmin' || 'Admin'
      GF_AUTH_GENERIC_OAUTH_SKIP_ORG_ROLE_SYNC=false
    '';

    sops.templates."grafana-datasources.yaml".content = ''
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          access: proxy
          url: http://${rootCfg.prometheus.name}:9090
          isDefault: true
          editable: true
    '';
  };
}
