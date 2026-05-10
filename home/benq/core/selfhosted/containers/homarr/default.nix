{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.homarr;
  hostDataPath = "${common.dataDir}/homarr/data";
in
{
  options.selfhosted.homarr = {
    name = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
  };

  config = {
    sops.secrets = {
      "homarr/enc_key" = { };
    };

    services.podman.containers."${cfg.name}" = {
      image = "ghcr.io/homarr-labs/homarr:v1.60.0";
      network = common.networkName;
      environment = {
        SECRET_ENCRYPTION_KEY = "${config.sops.secrets."homarr/enc_key".path}";
      };
      volumes = [
        "${hostDataPath}:/appdata"
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
