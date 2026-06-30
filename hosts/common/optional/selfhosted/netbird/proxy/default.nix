{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.netbird;
  hostDataPath = "${common.dataDir}/netbird/proxy";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.netbird.proxy = {
    name = mkOption {
      type = types.str;
    };
  };

  config = {
    virtualisation.oci-containers.containers.${cfg.proxy.name} = {
      image = "netbirdio/reverse-proxy:latest";
      environmentFiles = [ config.sops.templates."nb-proxy.env".path ];
      volumes = [
        "${hostDataPath}/certs:/certs:rw"
      ];
      ports = [
        "0.0.0.0:2222:2222/tcp" # gitea
        "0.0.0.0:7359:7359/udp" # jelly
        "0.0.0.0:51820:51820/udp"
      ];
      dependsOn = [ cfg.server.name ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=${cfg.proxy.name}"
        "--network=${common.network.name}"
      ];
    };

    systemd.services."${common.backend}-${cfg.proxy.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${cfg.server.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
      ];
      requires = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${cfg.server.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
      ];
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/certs
        chown -R ${common.user.uid}:${common.group.gid} ${hostDataPath}
        chmod -R 0755 ${hostDataPath}
      '';
    };
  };
}
