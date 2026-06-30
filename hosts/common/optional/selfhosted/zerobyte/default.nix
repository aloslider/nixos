{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.zerobyte;
  hostDataPath = "${common.dataDir}/zerobyte";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.zerobyte = {
    name = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
    hostPort = mkOption {
      type = types.port;
    };
  };

  config = {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "ghcr.io/nicotsx/zerobyte:latest";
      environmentFiles = [ config.sops.templates."zerobyte.env".path ];
      ports = [
        "0.0.0.0:${toString cfg.hostPort}:4096"
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostDataPath}/data:/var/lib/zerobyte"
        "${hostDataPath}/backups:/mydata"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
      ];
      requires = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
      ];
      partOf = [ "${common.backend}-${common.rootTarget.name}.target" ];
      wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/{data,backups}
      '';
    };
  };
}
