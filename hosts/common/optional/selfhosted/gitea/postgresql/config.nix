{ config, ... }:
let
  cfg = config.selfhosted.gitea;
in
{
  sops.templates."gitea-db.env".content = ''
    POSTGRES_DB=gitea
    POSTGRES_USER=gitea
    POSTGRES_PASSWORD=${config.sops.placeholder."gitea/db_password"}
  '';
}
