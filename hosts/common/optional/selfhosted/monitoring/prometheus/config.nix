{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.monitoring;
in
{
  config = mkIf rootCfg.enable {
    sops.templates."prometheus.yml".restartUnits = [ "${common.backend}-${rootCfg.prometheus.name}.service" ];
    sops.templates."prometheus.yml".content = ''
      global:
        scrape_interval: 15s
        evaluation_interval: 15s
      scrape_configs:
        - job_name: prometheus
          static_configs:
            - targets:
                - localhost:9090
        - job_name: node
          static_configs:
            - targets:
                - ${rootCfg.nodeExporter.name}:9100
    '';
  };
}
