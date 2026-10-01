{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.netbird;
in
{
  config = mkIf rootCfg.enable {
    sops.templates."nb-proxy.env".content = ''
      NB_PROXY_DEBUG_LOGS=false
      NB_PROXY_PROXY_PROTOCOL=true
      NB_PROXY_MANAGEMENT_ADDRESS=http://${rootCfg.server.name}:80
      NB_PROXY_ALLOW_INSECURE=true
      NB_PROXY_DOMAIN=${rootCfg.subdomain}.${config.sops.placeholder."domains/serv"}
      NB_PROXY_ADDRESS=:8443
      NB_PROXY_TOKEN=${config.sops.placeholder."netbird/proxy/token"}
      NB_PROXY_FORWARDED_PROTO=https
      NB_PROXY_CERTIFICATE_DIRECTORY=/certs
      NB_PROXY_ACME_CERTIFICATES=true
      NB_PROXY_ACME_CHALLENGE_TYPE=tls-alpn-01
      NB_PROXY_TRUSTED_PROXIES=${rootCfg.traefik.ip}
    '';
  };
}
