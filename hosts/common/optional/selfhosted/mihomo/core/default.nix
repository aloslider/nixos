{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.mihomo;
  cfg = rootCfg.core;
  hostDataPath = "${common.dataDir}/mihomo";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.mihomo.core = {
    name = mkOption {
      type = types.str;
    };
    hostMixedPort = mkOption {
      type = types.port;
    };
    hostApiPort = mkOption {
      type = types.port;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/metacubex/mihomo:v1.19.30";
      ports = [
        "127.0.0.1:${toString cfg.hostMixedPort}:7890"
        "0.0.0.0:${toString cfg.hostApiPort}:9090"
      ];
      volumes = [
        "${hostDataPath}:/root/.config/mihomo"
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
        mkdir -p ${hostDataPath}/providers
        cp -f ${config.sops.templates."mihomo.yaml".path} ${hostDataPath}/config.yaml
        chmod 644 ${hostDataPath}/config.yaml
      '';
    };
  };
}
