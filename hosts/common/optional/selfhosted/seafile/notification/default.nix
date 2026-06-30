{ config, lib, pkgs, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.seafile;
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

  config = {
    virtualisation.oci-containers.containers.${cfg.notification.name} = {
      image = "docker.io/seafileltd/notification-server:13.0-latest";
      ports = [
        "0.0.0.0:${toString cfg.notification.hostHttpPort}:8083"
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

    systemd.services."${common.backend}-${cfg.notification.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
        "${common.backend}-${cfg.mariadb.name}.service"
        "${common.backend}-${cfg.server.name}.service"
      ];
      requires = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
        "${common.backend}-${cfg.mariadb.name}.service"
        "${common.backend}-${cfg.server.name}.service"
      ];
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
      path = with pkgs; [ curl gawk ];
      preStart = ''
        echo "Waiting for Seafile server to be ready..."
        for i in {1..60}; do
          status=$(curl -sI --max-time 5 "http://localhost:${toString cfg.server.hostHttpPort}" | head -1 | awk '{print $2}')
          
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
