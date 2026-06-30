{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.pocket-id;
  hostDataPath = "${common.dataDir}/pocket-id";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.pocket-id = {
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
      image = "ghcr.io/pocket-id/pocket-id:latest";
      ports = [
        "0.0.0.0:${toString cfg.hostPort}:1411"
      ];
      user = "${common.user.uid}:${common.group.gid}";
      environmentFiles = [ config.sops.templates."pocket-id.env".path ];
      volumes = [
        "${hostDataPath}/data:/app/data"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
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
        mkdir -p ${hostDataPath}/letsencrypt
        chown -R ${common.user.uid}:${common.group.gid} ${hostDataPath}
        chmod -R 0775 ${hostDataPath}
      '';
    };
  };
}
