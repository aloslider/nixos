{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.netbird;
  cfg = config.selfhosted.netbird.proxy;
  hostDataPath = "${common.dataDir}/netbird/proxy";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.netbird.proxy = {
    name = mkOption {
      type = types.str;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/netbirdio/reverse-proxy:0.77.0";
      environmentFiles = [ config.sops.templates."nb-proxy.env".path ];
      volumes = [
        "${hostDataPath}/certs:/certs:rw"
      ];
      ports = [
        "0.0.0.0:2222:2222/tcp"   # gitea
        "0.0.0.0:7359:7359/udp"   # jelly
        "0.0.0.0:51820:51820/udp" # netbird stunt
        # "0.0.0.0:9090:9090/tcp"   # mihomo controller
      ];
      dependsOn = [ rootCfg.server.name ];
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
      requires = [ "${common.backend}-${rootCfg.server.name}.service" ];
      after = [ "${common.backend}-${rootCfg.server.name}.service" ];
      preStart = ''
        mkdir -p ${hostDataPath}/certs
        chown -R ${common.user.uid}:${common.group.gid} ${hostDataPath}
        chmod -R 0755 ${hostDataPath}
      '';
    };
  };
}
