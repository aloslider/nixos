{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.jellyfin;
  hostDataPath = "${common.dataDir}/jellyfin";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.jellyfin = {
    name = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
    hostHttpPort = mkOption {
      type = types.port;
    };
    hostUdpPort = mkOption {
      type = types.port;
    };
  };

  config = {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/jellyfin/jellyfin:10.11.11";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:8096"
        "0.0.0.0:${toString cfg.hostUdpPort}:7359"
      ];
      user = "${common.user.uid}:${common.group.gid}";
      environmentFiles = [ config.sops.templates."jellyfin.env".path ];
      volumes = [
        "${hostDataPath}/config:/config"
        "${hostDataPath}/cache:/cache"
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
        mkdir -p ${hostDataPath}/{config,cache}
        chown -R ${common.user.uid}:${common.group.gid} ${hostDataPath}
        chmod -R 0775 ${hostDataPath}
      '';
    };
  };
}
