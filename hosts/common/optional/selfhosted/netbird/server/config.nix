{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.netbird;
  nbDomain = "${config.selfhosted.netbird.subdomain}.${config.sops.placeholder."domains/serv"}";
in
{
  config = mkIf rootCfg.enable {
    sops.templates."nb-server.yaml".content = ''
      server:
        listenAddress: ":80"
        exposedAddress: "https://${nbDomain}:443"
        stunPorts:
          - 3478
        metricsPort: 9090
        healthcheckAddress: ":9000"
        logLevel: "info"
        logFile: "console"

        authSecret: "${config.sops.placeholder."netbird/server/auth_secret"}"

        auth:
          issuer: "https://${nbDomain}/oauth2"
          dashboardRedirectURIs:
            - "https://${nbDomain}/nb-auth"
            - "https://${nbDomain}/nb-silent-auth"
          cliRedirectURIs:
            - "http://localhost:53000/"
          localAuthDisabled: false

        store:
          engine: "sqlite"
          encryptionKey: "${config.sops.placeholder."netbird/server/enc_key"}"

        reverseProxy:
          trustedHTTPProxies:
            - "${rootCfg.traefik.ip}/32"
    '';
  };
}
