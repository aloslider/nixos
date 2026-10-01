{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.mail;
  cfg = config.selfhosted.mail.bulwark;
  hostDataPath = "${common.dataDir}/bulwark";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.mail.bulwark = {
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
      image = "ghcr.io/bulwarkmail/webmail-beta:sha-62e0760";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:3000"
      ];
      environmentFiles = [ config.sops.templates."bulwark.env".path ];
      volumes = [
        "${hostDataPath}/settings:/app/data/settings"
        "${hostDataPath}/admin:/app/data/admin"
        "${hostDataPath}/admin-state:/app/data/admin-state"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
        "--health-cmd=wget --no-verbose --tries=1 --spider http://127.0.0.1:3000/api/health || exit 1"
        "--health-interval=30s"
        "--health-start-period=20s"
        "--health-timeout=5s"
        "--health-retries=5"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      requires = [ "${common.backend}-${rootCfg.stalwart.name}.service" ];
      after = [ "${common.backend}-${rootCfg.stalwart.name}.service" ];
      preStart = ''
        mkdir -p ${hostDataPath}/{settings,admin,admin-state}
        chown -R 1001:65533 ${hostDataPath}/{settings,admin,admin-state}
      '';
    };
  };
}
