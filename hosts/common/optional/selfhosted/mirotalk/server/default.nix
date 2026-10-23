{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.mirotalk;
  cfg = rootCfg.server;
in
{
  imports = [ ./config.nix ];

  options.selfhosted.mirotalk.server = {
    name = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
    hostHttpPort = mkOption {
      type = types.port;
    };
    minPort = mkOption {
      type = types.port;
    };
    maxPort = mkOption {
      type = types.port;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "docker.io/mirotalk/sfu@sha256:0e2bba6dde0be9c6b2138b9ff988aa46ec23c7421a6313551c13735355081a17"; # 2.6.79 (2026-10-23)
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:3010"
        "0.0.0.0:${toString cfg.minPort}-${toString cfg.maxPort}:${toString cfg.minPort}-${toString cfg.maxPort}/tcp"
        "0.0.0.0:${toString cfg.minPort}-${toString cfg.maxPort}:${toString cfg.minPort}-${toString cfg.maxPort}/udp"
      ];
      user = "${common.user.uid}:${common.group.gid}";
      environmentFiles = [ config.sops.templates."mirotalk.env".path ];
      volumes = [
        "${config.sops.templates."mirotalk.env".path}:/src/.env:ro"
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
    };
  };
}
