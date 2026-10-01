{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.seafile;
  cfg = rootCfg.collabora;
in
{
  imports = [ ./config.nix ];

  options.selfhosted.seafile.collabora = {
    name = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
    hostHttpPort = mkOption {
      type = types.port;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/collabora/code:26.04.3.1.1";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:9980"
      ];
      environmentFiles = [ config.sops.templates."collabora.env".path ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
        "--cap-add=MKNOD"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      after = [ "${common.backend}-${rootCfg.server.name}.service" ];
      requires = [ "${common.backend}-${rootCfg.server.name}.service" ];
    };
  };
}
