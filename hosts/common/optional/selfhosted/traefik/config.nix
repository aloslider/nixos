{ config, ... }:
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.netbird;
in
{
  sops.templates."traefik.env".content = ''
    TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_EMAIL=${config.sops.placeholder."letsEncrypt/email"}
  '';

  sops.templates."traefik-static-config.yaml".content = ''
    entryPoints:
      web:
        address: ":80"
        http:
          redirections:
            entrypoint:
              to: websecure
              scheme: https
      websecure:
        address: ":443"
        allowACMEByPass: true
        transport:
          respondingTimeouts:
            readTimeout: 0
            writeTimeout: 0
            idleTimeout: 0
        proxyProtocol:
          trustedIPs:
            - "${common.network.address}/${common.network.mask}"
    
    serversTransport:
      forwardingTimeouts:
        responseHeaderTimeout: 0
        idleConnTimeout: 0
    
    providers:
      docker:
        exposedByDefault: false
        network: "${common.network.name}"
      file:
        filename: /etc/traefik/dynamic.yaml
        watch: true

    certificatesResolvers:
      letsencrypt:
        acme:
          storage: /letsencrypt/acme.json
          tlsChallenge: true
  '';

  sops.templates."traefik-dynamic-config.yaml".content = ''
    http:
      routers:
        netbird-dashboard:
          entryPoints:
            - websecure
          rule: "Host(`${cfg.subdomain}.${config.sops.placeholder."domains/serv"}`)"
          service: dashboard
          priority: 1
          tls:
            certResolver: letsencrypt

        netbird-backend:
          entryPoints:
            - websecure
          rule: "Host(`${cfg.subdomain}.${config.sops.placeholder."domains/serv"}`) && (PathPrefix(`/relay`) || PathPrefix(`/ws-proxy/`) || PathPrefix(`/api`) || PathPrefix(`/oauth2`))"
          service: netbird-server
          priority: 100
          tls:
            certResolver: letsencrypt

        netbird-grpc:
          entryPoints:
            - websecure
          rule: "Host(`${cfg.subdomain}.${config.sops.placeholder."domains/serv"}`) && (PathPrefix(`/signalexchange.SignalExchange/`) || PathPrefix(`/management.ManagementService/`))"
          service: netbird-server-h2c
          priority: 100
          tls:
            certResolver: letsencrypt

      services:
        dashboard:
          loadBalancer:
            servers:
              - url: "http://${cfg.dashboard.name}:80"
        netbird-server:
          loadBalancer:
            servers:
              - url: "http://${cfg.server.name}:80"
        netbird-server-h2c:
          loadBalancer:
            servers:
              - url: "h2c://${cfg.server.name}:80"
    tcp:
      serversTransports:
        pp-v2:
          proxyProtocol:
            version: 2

      routers:
        proxy-passthrough:
          entrypoints:
            - websecure
          rule: HostSNI(`*`)
          service: proxy-tls
          priority: 1
          tls:
            passthrough: true

      services:
        proxy-tls:
          loadBalancer:
            serversTransport: pp-v2@file
            servers:
              - address: "${cfg.proxy.name}:8443"
  '';
}
