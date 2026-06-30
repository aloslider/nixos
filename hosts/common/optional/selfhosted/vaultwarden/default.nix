{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.vaultwarden;
  hostDataPath = "${common.dataDir}/vaultwarden";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.vaultwarden = {
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
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "vaultwarden/server:latest";
      ports = [
        "0.0.0.0:${toString cfg.hostPort}:80"
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
        mkdir -p ${hostDataPath}/data
        chown -R ${common.user.uid}:${common.group.gid} ${hostDataPath}
        chmod -R 0775 ${hostDataPath}
      '';
    };
  };
}
