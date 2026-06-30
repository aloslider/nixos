{ config, lib, ... }:
with lib;
let
  cfg = config.selfhosted;
  domain = "${config.sops.placeholder."domains/serv"}";
  zerobyteDomain = "${cfg.zerobyte.subdomain}.${domain}";
  trustedOrigins = [
    "https://${zerobyteDomain}"
    "https://${cfg.pocket-id.subdomain}.${domain}"
  ];
in
{
  sops.secrets = {
    "zerobyte/app_secret" = { };
  };

  sops.templates."zerobyte.env".content = ''
    TZ=${config.time.timeZone}
    BASE_URL=https://${zerobyteDomain}
    APP_SECRET=${config.sops.placeholder."zerobyte/app_secret"}
    TRUST_PROXY=true
    TRUSTED_ORIGINS=${(concatStringsSep "," trustedOrigins)}
  '';
}
