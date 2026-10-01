{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.netbird;
  cfg = rootCfg.traefik;
  hostDataPath = "${common.dataDir}/traefik";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.netbird.traefik = {
    name = mkOption {
      type = types.str;
    };
    ip = mkOption {
      type = types.str;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/traefik:v3.7.4";
      environmentFiles = [ config.sops.templates."traefik.env".path ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
        "${config.sops.templates."traefik-static-config.yaml".path}:/etc/traefik/traefik.yaml:ro"
        "${config.sops.templates."traefik-dynamic-config.yaml".path}:/etc/traefik/dynamic.yaml:ro"
        "${hostDataPath}/letsencrypt:/letsencrypt:rw"
      ];
      ports = [
        "0.0.0.0:80:80"
        "0.0.0.0:443:443"
      ];
      cmd = [
        "--log.level=INFO"
        "--accesslog=true"
        "--configfile=/etc/traefik/traefik.yaml"
      ];
      log-driver = "journald";
      extraOptions = [
        "--ip=172.30.0.10"
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
      preStart = ''
        mkdir -p ${hostDataPath}/letsencrypt
        chown -R ${common.user.uid}:${common.group.gid} ${hostDataPath}
        chmod -R 0600 ${hostDataPath}
      '';
    };
  };
}
