{ config, ... }:
let
  cfg = config.selfhosted.pocket-id;
in
{
  sops.secrets = {
    "pocket_id/enc_key" = { };
  };

  sops.templates."pocket-id.env" = {
    content = ''
      APP_URL=https://${cfg.subdomain}.${config.sops.placeholder."domains/serv"}
      ENCRYPTION_KEY=${config.sops.placeholder."pocket_id/enc_key"}
      TRUST_PROXY=true
      ANALYTICS_DISABLED=true
      PUID=1000
      PGID=1000
    '';
  };
}
