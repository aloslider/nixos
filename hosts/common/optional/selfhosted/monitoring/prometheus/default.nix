{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.monitoring;
  cfg = rootCfg.prometheus;
  hostDataPath = "${common.dataDir}/prometheus";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.monitoring.prometheus = {
    name = mkOption {
      type = types.str;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "docker.io/prom/prometheus:v3.15.0";
      volumes = [
        "${hostDataPath}/data:/prometheus"
        "${hostDataPath}/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro"
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
      after = [ "${common.backend}-${rootCfg.nodeExporter.name}.service" ];
      preStart = ''
        mkdir -p ${hostDataPath}/data ${hostDataPath}/monitoring
        cp -f ${config.sops.templates."prometheus.yml".path} ${hostDataPath}/monitoring/prometheus.yml
        chmod 644 ${hostDataPath}/monitoring/prometheus.yml
        chown -R 65534:65534 ${hostDataPath}
      '';
    };
  };
}
