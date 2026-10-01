{ config, lib, ... }:
with lib;
let
  cfg = config.selfhosted.zerobyte;
  domain = "${config.sops.placeholder."domains/serv"}";
  zerobyteDomain = "${cfg.subdomain}.${domain}";
  trustedOrigins = [
    "https://${zerobyteDomain}"
    "https://${config.selfhosted.pocket-id.subdomain}.${domain}"
  ];
in
{
  config = mkIf cfg.enable {
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
  };
}
