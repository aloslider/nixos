{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.netbird;
in
{
  imports = [ ./config.nix ];

  options.selfhosted.netbird.dashboard = {
    name = mkOption {
      type = types.str;
    };
  };

  config = {
    virtualisation.oci-containers.containers.${cfg.dashboard.name} = {
      image = "netbirdio/dashboard:latest";
      environmentFiles = [ config.sops.templates."nb-dashboard.env".path ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=${cfg.dashboard.name}"
        "--network=${common.network.name}"
      ];
    };

    systemd.services."${common.backend}-${cfg.dashboard.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "${common.backend}-${cfg.server.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
      ];
      requires = [
        "${common.backend}-${cfg.server.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
      ];
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
    };
  };
}
