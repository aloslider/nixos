{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.gitea;
  hostDataPath = "${common.dataDir}/gitea";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.gitea.gitea = {
    name = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
    hostWebPort = mkOption {
      type = types.port;
    };
    hostSshPort = mkOption {
      type = types.port;
    };
  };

  config = {
    virtualisation.oci-containers.containers."${cfg.gitea.name}" = {
      image = "gitea/gitea:latest";
      ports = [
        "0.0.0.0:${toString cfg.gitea.hostWebPort}:3000"
        "0.0.0.0:${toString cfg.gitea.hostSshPort}:2222"
      ];
      environmentFiles = [ config.sops.templates."gitea.env".path ];
      volumes = [
        "${hostDataPath}/data:/data"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
      ];
    };

    systemd.services."${common.backend}-${cfg.gitea.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "${common.backend}-${cfg.postgresql.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
      ];
      requires = [ 
        "${common.backend}-${cfg.postgresql.name}.service"
        "${common.backend}-${config.selfhosted.traefik.name}.service"
      ];
      partOf = [ "${common.backend}-${cfg.targetName}.target" ];
      wantedBy = [ "${common.backend}-${cfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/data
        chown -R ${common.user.uid}:${common.group.gid} ${hostDataPath}/data
        chmod -R 0775 ${hostDataPath}/data
      '';
      postStart =
        let
          engine =
            if common.backend == "podman" then
              pkgs.podman
            else if common.backend == "docker" then
              pkgs.docker
            else
              abort "Unknown backend ${common.backend}";
        in
        ''
          set -euo pipefail
          DOMAIN=$(cat ${config.sops.secrets."domains/serv".path})
          CLIENT_ID=$(cat ${config.sops.secrets."gitea/client_id".path})
          CLIENT_SECRET=$(cat ${config.sops.secrets."gitea/client_secret".path})

          for i in $(seq 1 30); do
            if ${pkgs.curl}/bin/curl -sf http://127.0.0.1:${toString cfg.gitea.hostWebPort}/api/v1/version >/dev/null 2>&1; then
              break
            fi
            echo "Waiting for Gitea to be ready... ($i/20)"
            sleep 5
          done

          if ${engine}/bin/${common.backend} exec --user ${common.user.uid} ${cfg.gitea.name} \
              gitea admin auth list 2>/dev/null | grep -q 'PocketID'; then
            echo "PocketID auth source already registered"
            exit 0
          fi

          ${engine}/bin/${common.backend} exec --user ${common.user.uid} ${cfg.gitea.name} \
            gitea admin auth add-oauth \
              --name "PocketID" \
              --provider "openidConnect" \
              --key "$CLIENT_ID" \
              --secret "$CLIENT_SECRET" \
              --auto-discover-url "https://${config.selfhosted.pocket-id.subdomain}.$DOMAIN/.well-known/openid-configuration" \
              --scopes "openid email profile" \
              --skip-local-2fa

          echo "PocketID auth source registered successfully"
        '';
    };
  };
}
