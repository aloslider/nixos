{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.pocket-id;
  hostDataPath = "${common.dataDir}/pocket-id/data";
in
{
  imports = [
    ./config.nix
  ];

  options.selfhosted.pocket-id = {
    name = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
  };

  config = {
    services.podman.containers.${cfg.name} = {
      image = "ghcr.io/pocket-id/pocket-id:v2";
      network = common.networkName;
      environmentFile = [ "${config.sops.templates."pocket-id.env".path}" ];
      volumes = [
        "${hostDataPath}:/app/data"
      ];
      autoStart = true;
      extraConfig = {
        Quadlet = {
          DefaultDependencies = false;
        };
        Container = {
          HealthCmd = ''"/app/pocket-id" "healthcheck"'';
          HealthInterval = "1m30s";
          HealthTimeout = "5s";
          HealthRetries = "2";
          HealthStartPeriod = "10s";
        };
      };
    };
  };
}
