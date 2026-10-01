{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.monitoring;
  cfg = rootCfg.grafana;
  hostDataPath = "${common.dataDir}/grafana";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.monitoring.grafana = {
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
      image = "docker.io/grafana/grafana:13.2.3";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:3000"
      ];
      environmentFiles = [ config.sops.templates."grafana.env".path ];
      volumes = [
        "${hostDataPath}/data:/var/lib/grafana"
        "${hostDataPath}/monitoring:/etc/grafana/provisioning:ro"
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
      requires = [ "${common.backend}-${rootCfg.prometheus.name}.service" ];
      after = [ "${common.backend}-${rootCfg.prometheus.name}.service" ];
      preStart = ''
        mkdir -p ${hostDataPath}/data ${hostDataPath}/monitoring/datasources
        cp -f ${config.sops.templates."grafana-datasources.yaml".path} ${hostDataPath}/monitoring/datasources/datasources.yaml
        chmod 644 ${hostDataPath}/monitoring/datasources/datasources.yaml
        chown -R 472:472 ${hostDataPath}
      '';
    };
  };
}
