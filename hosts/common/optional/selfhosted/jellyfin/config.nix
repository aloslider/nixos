{ config, ... }:
let
  cfg = config.selfhosted.jellyfin;
in
{
  sops.secrets = {
  };

  sops.templates."jellyfin.env".content = ''
  
  '';
}
