{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.gitea;
in
{
  config = mkIf rootCfg.enable {
    sops.templates."gitea-db.env".content = ''
      POSTGRES_DB=gitea
      POSTGRES_USER=gitea
      POSTGRES_PASSWORD=${config.sops.placeholder."gitea/db_password"}
    '';
  };
}
