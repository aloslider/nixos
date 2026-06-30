{ config, ... }:
let
  cfg = config.selfhosted.netbird;
in
{
  sops.templates."nb-proxy.env".content = ''
    NB_PROXY_DEBUG_LOGS=false
    NB_PROXY_PROXY_PROTOCOL=true
    NB_PROXY_MANAGEMENT_ADDRESS=http://${cfg.server.name}:80
    NB_PROXY_ALLOW_INSECURE=true
    NB_PROXY_DOMAIN=${cfg.subdomain}.${config.sops.placeholder."domains/serv"}
    NB_PROXY_ADDRESS=:8443
    NB_PROXY_TOKEN=${config.sops.placeholder."netbird/proxy/token"}
    NB_PROXY_FORWARDED_PROTO=https
    NB_PROXY_CERTIFICATE_DIRECTORY=/certs
    NB_PROXY_ACME_CERTIFICATES=true
    NB_PROXY_ACME_CHALLENGE_TYPE=tls-alpn-01
    NB_PROXY_TRUSTED_PROXIES=${config.selfhosted.traefik.ip}
  '';
}
