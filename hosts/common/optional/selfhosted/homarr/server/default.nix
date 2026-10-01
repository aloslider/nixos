{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.homarr;
  cfg = rootCfg.server;
  hostDataPath = "${common.dataDir}/homarr";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.homarr.server = {
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
      image = "ghcr.io/homarr-labs/homarr:latest";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:7575"
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
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/data
      '';
    };
  };
}
