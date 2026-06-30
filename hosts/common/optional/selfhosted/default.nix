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
    ./netbird
    ./pocket-id
    ./seafile
    ./traefik
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
        name = "jellyfin";
        subdomain = "media";
        hostHttpPort = 5040;
        hostUdpPort = 5041;
      };
      gitea = {
        targetName = "gitea";
        gitea = {
          name = "gitea";
          subdomain = "gitea";
          hostWebPort = 5060;
          hostSshPort = 5061;
        };
        postgresql = {
          name = "gitea-db";
        };
      };
      immich = {
        targetName = "immich";
        version = "v2";
        immich = {
          name = "immich";
          subdomain = "photos";
          hostPort = 5090;
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
      netbird = {
        targetName = "netbird";
        subdomain = "nb";
        dashboard = {
          name = "nb-dashboard";
        };
        proxy = {
          name = "nb-proxy";
        };
        server = {
          name = "nb-server";
        };
      };
      homarr = {
        name = "homarr";
        subdomain = "dash";
        hostPort = 5030;
      };
      pocket-id = {
        name = "pocket-id";
        subdomain = "id";
        hostPort = 5020;
      };
      seafile = {
        targetName = "seafile";
        server = {
          name = "sf-server";
          subdomain = "cloud";
          hostHttpPort = 5050;
        };
        mariadb = {
          name = "sf-db";
        };
        redis = {
          name = "sf-cache";
        };
        seadoc = {
          name = "sf-seadoc";
          hostHttpPort = 5051;
        };
        notification = {
          name = "sf-notification";
          hostHttpPort = 5052;
        };
      };
      traefik = {
        name = "traefik";
        ip = "172.30.0.10";
      };
      vaultwarden = {
        name = "vaultwarden";
        subdomain = "vault";
        hostPort = 5010;
      };
      zapret2 = {
        name = "zapret2";
        socksPort = 6000;
        ssPort = 6001;
      };
      zerobyte = {
        name = "zerobyte";
        subdomain = "backup";
        hostPort = 5070;
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

    # Override to pass env file
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

    systemd.targets."${common.backend}-${common.rootTarget.name}" = {
      unitConfig = {
        Description = "Root target for homelab stack";
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services."${common.backend}-network-${common.network.name}" = {
      path = [ pkgs.${common.backend} ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${common.backend} network rm -f ${common.network.name}";
      };
      script = ''
        ${common.backend} network inspect ${common.network.name} \
        || ${common.backend} network create ${common.network.name} --driver=bridge --subnet=${common.network.address}/${common.network.mask} --gateway=${common.network.gateway}
      '';
      partOf = [ "${common.backend}-${common.rootTarget.name}.target" ];
      wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
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
