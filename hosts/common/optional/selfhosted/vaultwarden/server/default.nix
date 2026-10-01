{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.vaultwarden;
  cfg = rootCfg.server;
  hostDataPath = "${common.dataDir}/vaultwarden";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.vaultwarden.server = {
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
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "docker.io/vaultwarden/server:1.37.1";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:80"
      ];
      user = "${common.user.uid}:${common.group.gid}";
      environmentFiles = [ config.sops.templates."vaultwarden.env".path ];
      volumes = [
        "${hostDataPath}/data:/data"
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
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/data
        chown -R ${common.user.uid}:${common.group.gid} ${hostDataPath}
        chmod -R 0775 ${hostDataPath}
      '';
    };
  };
}
