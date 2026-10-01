{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.netbird;
  cfg = rootCfg.server;
  hostDataPath = "${common.dataDir}/netbird/server";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.netbird.server = {
    name = mkOption {
      type = types.str;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/netbirdio/netbird-server:0.77.0";
      volumes = [
        "${config.sops.templates."nb-server.yaml".path}:/etc/netbird/config.yaml:rw"
        "${hostDataPath}/data:/var/lib/netbird:rw"
      ];
      ports = [
        "0.0.0.0:3478:3478/udp"
      ];
      cmd = [
        "--config"
        "/etc/netbird/config.yaml"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=${cfg.name}"
        "--network=${common.network.name}"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      requires = [ "${common.backend}-${rootCfg.traefik.name}.service" ];
      after = [ "${common.backend}-${rootCfg.traefik.name}.service" ];
      preStart = ''
        mkdir -p ${hostDataPath}/data
        chown -R ${common.user.uid}:${common.group.gid} ${hostDataPath}
        chmod -R 0755 ${hostDataPath}
      '';
    };
  };
}
