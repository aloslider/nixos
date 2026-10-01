{ config, lib, pkgs, ... }:
with lib;
let
  common = config.selfhosted.common;
  rootCfg = config.selfhosted.mail;
  cfg = rootCfg.stalwart;
  planPath = config.sops.templates."stalwart-oidc-plan.json".path;
  cliEnvPath = config.sops.templates."stalwart-cli.env".path;
  hostDataPath = "${common.dataDir}/stalwart";
in
{
  imports = [ ./config.nix ];

  options.selfhosted.mail.stalwart = {
    name = mkOption {
      type = types.str;
    };
    subdomain = mkOption {
      type = types.str;
    };
    hostHttpPort = mkOption {
      type = types.port;
    };
    hostImapsPort = mkOption {
      type = types.port;
    };
    hostSubmissionPort = mkOption {
      type = types.port;
    };
    hostSmtpsPort = mkOption {
      type = types.port;
    };
    hostManageSievePort = mkOption {
      type = types.port;
    };
    hostSmtpPort = mkOption {
      type = types.port;
    };
  };

  config = mkIf rootCfg.enable {
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "docker.io/stalwartlabs/stalwart:v0.16";
      ports = [
        "0.0.0.0:${toString cfg.hostHttpPort}:8080"
        "0.0.0.0:${toString cfg.hostImapsPort}:993"
        "0.0.0.0:${toString cfg.hostManageSievePort}:4190"
        "0.0.0.0:${toString cfg.hostSmtpPort}:25"
        "0.0.0.0:${toString cfg.hostSmtpsPort}:465"
        "0.0.0.0:${toString cfg.hostSubmissionPort}:587"
      ];
      environmentFiles = [ config.sops.templates."stalwart.env".path ];
      volumes = [
        "${hostDataPath}/data:/var/lib/stalwart"
        "${hostDataPath}/config:/etc/stalwart"
      ];
      cmd = [
        "--config"
        "/etc/stalwart/config.json"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${common.network.name}"
        "--health-cmd=curl -sf -o /dev/null http://localhost:8080/healthz/ready"
        "--health-interval=20s"
        "--health-start-period=30s"
        "--health-timeout=5s"
        "--health-retries=10"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      preStart = ''
        mkdir -p ${hostDataPath}/{config,data}
        chown -R 2000:2000 ${hostDataPath} 2>/dev/null || chmod 775 ${hostDataPath}
        chmod 775 ${hostDataPath}/{config,data}
        cp -f ${config.sops.templates."stalwart-config.json".path} ${hostDataPath}/config/config.json
        chmod 644 ${hostDataPath}/config/config.json
      '';
    };

    systemd.services."${cfg.name}-oidc-apply" = {
      description = "Apply Stalwart OIDC directory plan";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        EnvironmentFile = cliEnvPath;
      };
      wantedBy = [ "${common.backend}-${rootCfg.targetName}.target" ];
      partOf = [ "${common.backend}-${rootCfg.targetName}.target" ];
      requires = [ "${common.backend}-${cfg.name}.service" ];
      after = [ "${common.backend}-${cfg.name}.service" ];
      restartTriggers = [
        planPath
        cliEnvPath
        config.sops.templates."stalwart.env".path
        config.sops.secrets."porkbun/serv/api_key".path
        config.sops.secrets."porkbun/serv/secret_key".path
        config.sops.secrets."letsEncrypt/email".path
      ];
      path = [
        pkgs.curl
        pkgs.jq
        pkgs.${common.backend}
      ];
      script = ''
        set -euo pipefail

        cli_image="ghcr.io/stalwartlabs/cli:1.0.12"

        ok=0
        for i in $(seq 1 60); do
          if curl -sf -o /dev/null "http://127.0.0.1:${toString cfg.hostHttpPort}/healthz/ready"; then
            ok=1
            break
          fi
          echo "Waiting for Stalwart container to become healthy... ($i/60)"
          sleep 1
        done
        if [ "$ok" -ne 1 ]; then
          echo "Stalwart did not become healthy in time" >&2
          exit 1
        fi

        if ! ${common.backend} image inspect "$cli_image" >/dev/null 2>&1; then
          ${common.backend} pull "$cli_image"
        fi

        jq -c '.[]' ${planPath} | ${common.backend} run --rm -i --network host \
          -e STALWART_URL \
          -e STALWART_USER \
          -e STALWART_PASSWORD \
          "$cli_image" \
          apply --stdin

        ${common.backend} restart ${cfg.name}

        ok=0
        for i in $(seq 1 60); do
          if curl -sf -o /dev/null "http://127.0.0.1:${toString cfg.hostHttpPort}/healthz/ready"; then
            ok=1
            break
          fi
          echo "Waiting for Stalwart after restart... ($i/60)"
          sleep 2
        done
        if [ "$ok" -ne 1 ]; then
          echo "Stalwart did not become healthy after OIDC apply restart" >&2
          exit 1
        fi
      '';
    };
  };
}
