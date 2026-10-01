{ config, lib, pkgs, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.seafile;
  cfg = rootCfg.notification;
  hostDataPath = "${common.dataDir}/seafile";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.seafile.notification = {
    name = mkOption {
      type = types.str;
    };
    hostHttpPort = mkOption {
      type = types.port;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/seafileltd/notification-server:13.0-latest";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:8083"
      ];
      environmentFiles = [ config.sops.templates."seafile-notification.env".path ];
      volumes = [
        "${hostDataPath}/notification/logs:/shared/seafile/logs"
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
      requires = [
        "${common.backend}-${rootCfg.mariadb.name}.service"
        "${common.backend}-${rootCfg.server.name}.service"
      ];
      after = [
        "${common.backend}-${rootCfg.mariadb.name}.service"
        "${common.backend}-${rootCfg.server.name}.service"
      ];
      path = with pkgs; [ curl gawk ];
      preStart = ''
        echo "Waiting for Seafile server to be ready..."
        for i in {1..60}; do
          status=$(curl -sI --max-time 5 "http://localhost:${toString rootCfg.server.hostHttpPort}" | head -1 | awk '{print $2}')
          
          if [[ "$status" =~ ^(200|301|302)$ ]]; then
            echo "Seafile server is up (HTTP $status, attempt $i)"
            break
          fi
          
          echo "Seafile not ready yet (status: $status) ... ($i/60)"
          sleep 1
        done

        mkdir -p ${hostDataPath}/notification
      '';
    };
  };
}
