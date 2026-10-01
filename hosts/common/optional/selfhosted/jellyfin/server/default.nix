{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.jellyfin;
  cfg = rootCfg.server;
  hostDataPath = "${common.dataDir}/jellyfin";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.jellyfin.server = {
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

  config = mkIf rootCfg.enable {
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
      wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
      partOf = [ "${common.backend}-${common.rootTarget.name}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/{config,cache}
        chown -R ${common.user.uid}:${common.group.gid} ${hostDataPath}
        chmod -R 0775 ${hostDataPath}
      '';
    };
  };
}
