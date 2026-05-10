{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.netbird;
  hostDataPath = "${common.dataDir}/netbird";
in
{
  imports = [
    ./config.nix
  ];

  options.selfhosted.netbird = {
    subdomain = mkOption {
      type = types.str;
    };
    traefik = {
      name = mkOption {
        type = types.str;
      };
    };
    dashboard = {
      name = mkOption {
        type = types.str;
      };
    };
    server = {
      name = mkOption {
        type = types.str;
      };
    };
    proxy = {
      name = mkOption {
        type = types.str;
      };
    };
  };

  config = {
    services.podman.containers.${cfg.traefik.name} = {
      image = "traefik:v3.6";
      network = common.networkName;
      ports = [
        "0.0.0.0:80:80"
        "0.0.0.0:443:443"
      ];
      autoStart = true;
      volumes = [
        "${hostDataPath}/traefik/letsencrypt:/letsencrypt"
        "${config.sops.templates."nb-traefik.yaml".path}:/etc/traefik/config.yaml"
        "${config.sops.templates."nb-traefik-dynamic.yaml".path}:/etc/traefik/dynamic.yaml"
      ];
      extraConfig = {
        Quadlet = {
          DefaultDependencies = false;
        };
      };
    };

    services.podman.containers.${cfg.dashboard.name} = {
      image = "netbirdio/dashboard:v2.37.1";
      network = common.networkName;
      environmentFile = [ "${config.sops.templates."nb-dashboard.env".path}" ];
      autoStart = true;
      extraConfig = {
        Quadlet = {
          DefaultDependencies = false;
        };
      };
    };

    services.podman.containers.${cfg.server.name} = {
      image = "netbirdio/netbird-server:0.70.5";
      network = common.networkName;
      ports = [
        "0.0.0.0:3478:3478/udp"
      ];
      autoStart = true;
      volumes = [
        "${hostDataPath}/server/data:/var/lib/netbird"
        "${config.sops.templates."nb-config.yaml".path}:/etc/netbird/config.yaml"
      ];
      extraConfig = {
        Quadlet = {
          DefaultDependencies = false;
        };
      };
    };

    services.podman.containers.${cfg.proxy.name} = {
      image = "netbirdio/reverse-proxy:0.70.5";
      network = common.networkName;
      environmentFile = [ "${config.sops.templates."nb-proxy.env".path}" ];
      autoStart = true;
      volumes = [
        "${hostDataPath}/proxy/certs:/certs"
      ];
      extraConfig = {
        Quadlet = {
          DefaultDependencies = false;
        };
      };
    };
  };
}
