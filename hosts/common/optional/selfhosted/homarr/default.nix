{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.homarr;
  hostDataPath = "${common.dataDir}/homarr";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.homarr = {
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
      image = "ghcr.io/homarr-labs/homarr:latest";
      ports = [
        "0.0.0.0:${toString cfg.hostPort}:7575"
      ];
      environmentFiles = [ config.sops.templates."homarr.env".path ];
      volumes = [
        "${hostDataPath}/data:/appdata"
        "/var/run/docker.sock:/var/run/docker.sock"
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
      '';
    };
  };
}
