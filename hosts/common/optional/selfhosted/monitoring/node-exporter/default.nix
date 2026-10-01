{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.monitoring;
  cfg = rootCfg.nodeExporter;
in
{
  options.selfhosted.monitoring.nodeExporter = {
    name = mkOption {
      type = types.str;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "docker.io/prom/node-exporter:v1.12.1";
      cmd = [ "--path.rootfs=/host" ];
      volumes = [
        "/:/host:ro,rslave"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
        "--pid=host"
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
