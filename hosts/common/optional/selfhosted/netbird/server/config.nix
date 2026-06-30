{ config, ... }:
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.netbird;
  fullDomain = "${cfg.subdomain}.${config.sops.placeholder."domains/serv"}";
in
{
  sops.secrets = {
    "netbird/server/auth_secret" = { };
    "netbird/server/enc_key" = { };
  };

  sops.templates."nb-server.yaml".content = ''
    server:
      listenAddress: ":80"
      exposedAddress: "https://${fullDomain}:443"
      stunPorts:
        - 3478
      metricsPort: 9090
      healthcheckAddress: ":9000"
      logLevel: "info"
      logFile: "console"

      authSecret: "${config.sops.placeholder."netbird/server/auth_secret"}"

      auth:
        issuer: "https://${fullDomain}/oauth2"
        dashboardRedirectURIs:
          - "https://${fullDomain}/nb-auth"
          - "https://${fullDomain}/nb-silent-auth"
        cliRedirectURIs:
          - "http://localhost:53000/"
        localAuthDisabled: false

      store:
        engine: "sqlite"
        encryptionKey: "${config.sops.placeholder."netbird/server/enc_key"}"

      reverseProxy:
        trustedHTTPProxies:
          - "${config.selfhosted.traefik.ip}/32"
  '';
}
