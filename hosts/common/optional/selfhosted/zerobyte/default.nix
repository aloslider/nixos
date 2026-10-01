{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.zerobyte;
  hostDataPath = "${common.dataDir}/zerobyte";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.zerobyte = {
    enable = mkEnableOption "Enable ${cfg.targetName}";
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

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "ghcr.io/nicotsx/zerobyte:v0.41";
      environmentFiles = [ config.sops.templates."zerobyte.env".path ];
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:4096"
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostDataPath}/data:/var/lib/zerobyte"
        "${hostDataPath}/backups:/mydata"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
      partOf = [ "${common.backend}-${common.rootTarget.name}.target" ];
      after = [ "${common.backend}-${common.rootTarget.name}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/{data,backups}
      '';
    };
  };
}
