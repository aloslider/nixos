{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.vaultwarden;
  hostDataPath = "${common.dataDir}/vaultwarden/data";
in
{
  imports = [
    ./config.nix
  ];

  options.selfhosted.vaultwarden = {
    enable = mkEnableOption "Enable container";
    name = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
  };

  config = {
    services.podman.containers.${cfg.name} = {
      image = "docker.io/vaultwarden/server:1.36.0";
      network = config.selfhosted.common.networkName;
      environmentFile = [ "${config.sops.templates."vaultwarden.env".path}" ];
      volumes = [
        "${hostDataPath}:/data"
      ];
      autoStart = true;
      extraConfig = {
        Quadlet = {
          DefaultDependencies = false;
        };
      };
    };
  };
}
