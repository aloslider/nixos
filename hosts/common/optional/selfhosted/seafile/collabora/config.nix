{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.seafile;
  cfg = rootCfg.collabora;
  domain = config.sops.placeholder."domains/serv";
  seafileUrl = "https://${rootCfg.server.subdomain}.${domain}";
in
{
  config = mkIf rootCfg.enable {
    sops.templates."collabora.env".content = ''
      TZ=${config.time.timeZone}
      DONT_GEN_SSL_CERT=true
      server_name=${cfg.subdomain}.${domain}
      aliasgroup1=${seafileUrl}:443
      extra_params=--o:ssl.enable=false --o:ssl.termination=true --o:net.frame_ancestors=${seafileUrl} --o:logging.level=warning
    '';
  };
}
