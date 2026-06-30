{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.gitea;
in
{
  imports = [
    ./gitea
    ./postgresql
  ];

  options.selfhosted.gitea = {
    targetName = mkOption {
      type = types.str;
    };
  };

  config = {
    sops.secrets = {
      "gitea/db_password" = { };
      "gitea/client_id" = { };
      "gitea/client_secret" = { };
    };

    systemd.targets."${common.backend}-${cfg.targetName}" = {
      unitConfig = {
        Description = "Root target for ${cfg.targetName}";
      };
      wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
    };
  };
}
