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
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "docker.io/mirotalk/p2p@sha256:c05675e2e3e8a2bb1ee63f07dcaaf8523a30b4dee4d1e594594ff5e36c959b07"; # 1.9.39 (2026-09-03)
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:3000"
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
      after = lib.optionals config.selfhosted.turn.enable [
        "${common.backend}-${config.selfhosted.turn.name}.service"
      ];
    };
  };
}
