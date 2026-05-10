{ config, ... }:
let
  cfg = config.selfhosted.netbird;
  poCfg = config.selfhosted.pocket-id;
  domain = config.sops.placeholder."domains/serv";
  fullDomain = "${cfg.subdomain}.${domain}";
in
{
  sops.secrets = {
    "netbird/traefik/letsEncryptEmail" = { };
    "netbird/auth/client_id" = { };
    "netbird/auth/client_secret" = { };
    "netbird/server/auth_secret" = { };
    "netbird/server/enc_key" = { };
    "netbird/proxy/token" = { };
  };

  sops.templates."nb-traefik.yaml".content = ''
    log:
      level: INFO

    providers:
      file:
        filename: /etc/traefik/dynamic.yaml

    entryPoints:
      web:
        address: ":80"
        http:
          redirections:
            entryPoint:
              to: websecure
              scheme: https

      websecure:
        address: ":443"

    certificatesResolvers:
      letsencrypt:
        acme:
          email: ${config.sops.placeholder."netbird/traefik/letsEncryptEmail"}
          storage: /letsencrypt/acme.json
          tlsChallenge: true
  '';

  sops.templates."nb-traefik-dynamic.yaml".content =
    let
      nbServerName = "nb-server";
      nbServerH2cName = "nb-server-h2c";
      nbDashboardName = "nb-dashboard";
    in
    ''
      http:
        routers:
          nb-relay:
            rule: Host(`${fullDomain}`) && PathPrefix(`/relay`)
            entryPoints:
              - websecure
            tls:
              certResolver: letsencrypt
            service: ${nbServerName}
            priority: 110

          nb-ws-signal:
            rule: Host(`${fullDomain}`) && PathPrefix(`/ws-proxy/signal`)
            entryPoints:
              - websecure
            tls:
              certResolver: letsencrypt
            service: ${nbServerName}
            priority: 110

          nb-ws-management:
            rule: Host(`${fullDomain}`) && PathPrefix(`/ws-proxy/management`)
            entryPoints:
              - websecure
            tls:
              certResolver: letsencrypt
            service: ${nbServerName}
            priority: 110

          nb-grpc-signal:
            rule: Host(`${fullDomain}`) && PathPrefix(`/signalexchange.SignalExchange/`)
            entryPoints:
              - websecure
            tls:
              certResolver: letsencrypt
            service: ${nbServerH2cName}
            priority: 100

          nb-grpc-management:
            rule: Host(`${fullDomain}`) && PathPrefix(`/management.ManagementService/`)
            entryPoints:
              - websecure
            tls:
              certResolver: letsencrypt
            service: ${nbServerH2cName}
            priority: 100

          nb-api:
            rule: Host(`${fullDomain}`) && PathPrefix(`/api`)
            entryPoints:
              - websecure
            tls:
              certResolver: letsencrypt
            service: ${nbServerName}
            priority: 90

          ${nbDashboardName}:
            rule: Host(`${fullDomain}`)
            entryPoints:
              - websecure
            tls:
              certResolver: letsencrypt
            service: ${nbDashboardName}
            priority: 10

        services:
          ${nbServerName}:
            loadBalancer:
              servers:
                - url: http://${cfg.server.name}:80

          ${nbServerH2cName}:
            loadBalancer:
              servers:
                - url: http://${cfg.server.name}:80
              scheme: h2c

          ${nbDashboardName}:
            loadBalancer:
              servers:
                - url: http://${cfg.dashboard.name}:80
      tcp:
        serversTransports:
          pp-v2:
            proxyProtocol:
              version: 2
    '';

  sops.templates."nb-dashboard.env".content = ''
    NETBIRD_MGMT_API_ENDPOINT=https://${fullDomain}
    NETBIRD_MGMT_GRPC_API_ENDPOINT=https://${fullDomain}

    AUTH_AUDIENCE=${cfg.dashboard.name}
    AUTH_CLIENT_ID=${config.sops.placeholder."netbird/auth/client_id"}
    AUTH_CLIENT_SECRET=${config.sops.placeholder."netbird/auth/client_secret"}
    AUTH_AUTHORITY=https://${poCfg.subdomain}.${domain}
    USE_AUTH0=false
    AUTH_SUPPORTED_SCOPES=openid profile email groups
    AUTH_REDIRECT_URI=/nb-auth
    AUTH_SILENT_REDIRECT_URI=/nb-silent-auth

    LETSENCRYPT_DOMAIN=none
    LETSENCRYPT_EMAIL=${config.sops.placeholder."netbird/traefik/letsEncryptEmail"}
  '';

  sops.templates."nb-config.yaml".content = ''
    server:
      listenAddress: ":80"
      exposedAddress: "https://${fullDomain}"
      stunPorts:
        - 3478
      metricsPort: 9090
      healthcheckAddress: ":9000"
      logLevel: "info"
      logFile: "console"

      authSecret: "${config.sops.placeholder."netbird/server/auth_secret"}"

      auth:
        issuer: "https://${poCfg.subdomain}.${domain}"
        clientID: "${config.sops.placeholder."netbird/auth/client_id"}"
        clientSecret: "${config.sops.placeholder."netbird/auth/client_secret"}"

      reverseProxy:
        trustedHTTPProxies:
          - "127.0.0.1/32"

      store:
        engine: "sqlite"
        encryptionKey: "${config.sops.placeholder."netbird/server/enc_key"}"
  '';

  sops.templates."nb-proxy.env".content = ''
    NB_PROXY_DOMAIN=${fullDomain}
    NB_PROXY_TOKEN=${config.sops.placeholder."netbird/proxy/token"}
    NB_PROXY_MANAGEMENT_ADDRESS=http://${cfg.server.name}:80
    NB_PROXY_ALLOW_INSECURE=true
    NB_PROXY_ADDRESS=:8443
    NB_PROXY_ACME_CERTIFICATES=true
    NB_PROXY_ACME_CHALLENGE_TYPE=tls-alpn-01
    NB_PROXY_CERTIFICATE_DIRECTORY=/certs
  '';
}
