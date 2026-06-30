{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.netbird;
  hostDataPath = "${common.dataDir}/netbird/server";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.netbird.server = {
    name = mkOption {
      type = types.str;
    };
  };

  config = {
    virtualisation.oci-containers.containers.${cfg.server.name} = {
      image = "netbirdio/netbird-server:latest";
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
        "--network-alias=${cfg.server.name}"
        "--network=${common.network.name}"
      ];
    };

    systemd.services."${common.backend}-${cfg.server.name}" = {
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
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/data
        chown -R ${common.user.uid}:${common.group.gid} ${hostDataPath}
        chmod -R 0755 ${hostDataPath}
      '';
    };
  };
}
