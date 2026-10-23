{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted;
in
{
  imports = [
    ./gitea
    ./homarr
    ./immich
    ./jellyfin
    ./mihomo
    ./mirotalk
    ./monitoring
    ./netbird
    ./pocket-id
    ./seafile
    ./stalwart
    ./turn
    ./vaultwarden
    ./zapret2
    ./zerobyte
  ];

  options.selfhosted.common = {
    backend = mkOption {
      type = types.str;
    };
    rootTarget = {
      name = mkOption {
        type = types.str;
      };
    };
    network = {
      name = mkOption {
        type = types.str;
      };
      address = mkOption {
        type = types.str;
      };
      mask = mkOption {
        type = types.str;
      };
      gateway = mkOption {
        type = types.str;
      };
    };
    dataDir = mkOption {
      type = types.str;
    };
    user = {
      name = mkOption {
        type = types.str;
      };
      uid = mkOption {
        type = types.str;
      };
    };
    group = {
      name = mkOption {
        type = types.str;
      };
      gid = mkOption {
        type = types.str;
      };
    };
  };

  config = {
    selfhosted = {
      common = {
        backend = "docker";
        rootTarget.name = "sh-root";
        network = {
          name = "selfhosted";
          address = "172.30.0.0";
          mask = "24";
          gateway = "172.30.0.1";
        };
        dataDir = "/mnt/data";
        user = {
          name = config.users.users.benq.name;
          uid = "1000";
        };
        group = {
          name = "users";
          gid = "1000";
        };
      };
      jellyfin = {
        enable = false;
        targetName = "jellyfin";
        server = {
          name = "jellyfin-server";
          subdomain = "media";
          hostHttpPort = 5040;
          hostUdpPort = 5041;
        };
      };
      gitea = {
        enable = true;
        targetName = "gitea";
        server = {
          name = "gitea-server";
          subdomain = "gitea";
          hostWebPort = 5060;
          hostSshPort = 5061;
          maxRepoLimit = 50;
        };
        postgresql = {
          name = "gitea-db";
        };
      };
      immich = {
        enable = true;
        targetName = "immich";
        subdomain = "photos";
        server = {
          name = "immich-server";
          hostHttpPort = 5090;
        };
        ml = {
          name = "immich-ml";
        };
        redis = {
          name = "immich-cache";
        };
        postgresql = {
          name = "immich-db";
          db = "immich";
          user = "immich";
        };
      };
      mihomo = {
        enable = false;
        targetName = "mihomo";
        dashboard = {
          name = "mihomo-zashboard";
          subdomain = "zash";
          hostHttpPort = 6020;
        };
        core = {
          name = "mihomo-core";
          hostMixedPort = 6021;
          hostApiPort = 6022;
        };
      };
      mirotalk = {
        enable = true;
        targetName = "mirotalk";
        server = {
          name = "mirotalk-server";
          subdomain = "meet";
          hostHttpPort = 5110;
          minPort = 40000;
          maxPort = 40100;
        };
      };
      turn = {
        enable = true;
        name = "turn-server";
        listenIP = "172.30.0.28";
        listenPort = 3479;
        minPort = 49160;
        maxPort = 49200;
      };
      netbird = {
        enable = true;
        targetName = "netbird";
        subdomain = "nb";
        dashboard = {
          name = "netbird-dashboard";
        };
        proxy = {
          name = "netbird-proxy";
        };
        server = {
          name = "netbird-server";
        };
        traefik = {
          name = "netbird-traefik";
          ip = "172.30.0.10";
        };
      };
      homarr = {
        enable = true;
        targetName = "homarr";
        server = {
          name = "homarr-server";
          subdomain = "dash";
          hostHttpPort = 5030;
        };
      };
      monitoring = {
        enable = true;
        targetName = "monitor";
        grafana = {
          name = "monitor-grafana";
          subdomain = "grafana";
          hostHttpPort = 5100;
        };
        prometheus = {
          name = "monitor-prometheus";
        };
        nodeExporter = {
          name = "monitor-node-exporter";
        };
      };
      pocket-id = {
        enable = true;
        targetName = "pocket-id";
        subdomain = "id";
        server = {
          name = "pocket-id-server";
          hostHttpPort = 5020;
        };
      };
      seafile = {
        enable = true;
        targetName = "seafile";
        server = {
          name = "seafile-server";
          subdomain = "cloud";
          hostHttpPort = 5050;
        };
        mariadb = {
          name = "seafile-db";
        };
        redis = {
          name = "seafile-cache";
        };
        seadoc = {
          name = "seafile-seadoc";
          hostHttpPort = 5051;
        };
        notification = {
          name = "seafile-notification";
          hostHttpPort = 5052;
        };
        collabora = {
          name = "seafile-collabora";
          subdomain = "office";
          hostHttpPort = 5053;
        };
        thumbnail = {
          name = "seafile-thumbnail";
          hostHttpPort = 5054;
        };
      };
      mail = {
        enable = true;
        targetName = "mail";
        hostPorts =
          let
            cfg = config.selfhosted.mail.stalwart;
          in
          [
            cfg.hostImapsPort
            cfg.hostManageSievePort
            cfg.hostSmtpPort
            cfg.hostSmtpsPort
            cfg.hostSubmissionPort
          ];
        bulwark = {
          name = "mail-bulwark";
          subdomain = "mail";
          hostHttpPort = 5087;
        };
        stalwart = {
          name = "mail-server";
          subdomain = "webmail";
          hostHttpPort = 5080;
          hostImapsPort = 993;
          hostManageSievePort = 4190;
          hostSmtpPort = 25;
          hostSmtpsPort = 465;
          hostSubmissionPort = 587;
        };
      };
      vaultwarden = {
        enable = true;
        targetName = "vaultwarden";
        server = {
          name = "vaultwarden-server";
          subdomain = "vault";
          hostHttpPort = 5010;
        };
      };
      zapret2 = {
        enable = false;
        name = "zapret2";
        socksPort = 6000;
        ssPort = 6001;
      };
      zerobyte = {
        enable = true;
        name = "zerobyte";
        subdomain = "backup";
        hostHttpPort = 5070;
      };
    };

    virtualisation = lib.mkMerge [
      { oci-containers.backend = config.selfhosted.common.backend; }
      (
        if config.selfhosted.common.backend == "docker" then
          {
            docker = {
              enable = true;
            };
          }
        else if config.selfhosted.common.backend == "podman" then
          {
            podman = {
              enable = true;
              dockerCompat = true;
            };
          }
        else
          abort "virtualisation.backend is not set"
      )
    ];

    services.netbird.clients = {
      homelab = {
        port = 51820;
        openFirewall = true;
        openInternalFirewall = true;
        login = {
          enable = true;
          setupKeyFile = config.sops.secrets."netbird/setup_keys/homelab".path;
        };
      };
    };

    sops.secrets = {
      "netbird/setup_keys/homelab" = { };
      "netbird/setup_keys/site" = { };
    };

    sops.templates."netbird-homelab.env".content = ''
      NB_MANAGEMENT_URL=https://${cfg.netbird.subdomain}.${config.sops.placeholder."domains/serv"}
    '';

    systemd.services = {
      "netbird-homelab" = {
        serviceConfig = {
          EnvironmentFile = [ config.sops.templates."netbird-homelab.env".path ];
        };
        after = [ "sops-nix.service" ];
        wants = [ "sops-nix.service" ];
      };
      "netbird-homelab-login" = {
        after = [ "sops-nix.service" ];
        wants = [ "sops-nix.service" ];
      };
    };

    systemd.services."${common.backend}-network-${common.network.name}" = {
      unitConfig = {
        Description = "Common network for selfhosted services stack";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${common.backend} network rm -f ${common.network.name}";
      };
      partOf = [ "${common.backend}-${common.rootTarget.name}.target" ];
      wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
      path = [ pkgs.${common.backend} ];
      script = ''
        ${common.backend} network inspect ${common.network.name} \
        || ${common.backend} network create ${common.network.name} --driver=bridge --subnet=${common.network.address}/${common.network.mask} --gateway=${common.network.gateway}
      '';
    };

    systemd.targets."${common.backend}-${common.rootTarget.name}" = {
      unitConfig = {
        Description = "Root target for homelab stack";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [
        "${common.backend}-network-${common.network.name}.service" # wait for network creation
        "${common.backend}-${config.selfhosted.netbird.traefik.name}.service"
      ];
      after = [
        "${common.backend}-network-${common.network.name}.service"
        "${common.backend}-${config.selfhosted.netbird.traefik.name}.service"
      ];
    };

    networking.firewall.interfaces = lib.mkMerge [
      (lib.mkIf (config.selfhosted.common.backend == "podman") (
        let
          matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
        in
        {
          "${matchAll}" = {
            allowedUDPPorts = [ 53 ];
          };
        }
      ))
    ];
  };
}
