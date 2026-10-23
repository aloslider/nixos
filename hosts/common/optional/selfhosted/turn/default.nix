{ config, lib, ... }:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.turn;
in
{
  imports = [ ./config.nix ];

  options.selfhosted.turn = {
    enable = mkEnableOption "Enable coturn server";
    name = mkOption {
      type = types.str;
    };
    listenIP = mkOption {
      type = types.str;
    };
    listenPort = mkOption {
      type = types.port;
    };
    minPort = mkOption {
      type = types.port;
    };
    maxPort = mkOption {
      type = types.port;
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.${cfg.name} = {
      image = "docker.io/coturn/coturn:4.6.3";
      cmd = [ "-c" "/etc/turnserver.conf" ];
      ports = [ 
          "0.0.0.0:${toString cfg.listenPort}:${toString cfg.listenPort}/udp"
        ]
        ++ map (port: "0.0.0.0:${toString port}:${toString port}/udp") (range cfg.minPort cfg.maxPort);
      volumes = [ "${config.sops.templates."turnserver.conf".path}:/etc/turnserver.conf:ro" ];
      log-driver = "journald";
      extraOptions = [ 
        "--network=${common.network.name}"
        "--ip=172.30.0.28"
      ];
    };

    systemd.services."${common.backend}-${cfg.name}" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
      partOf = [ "${common.backend}-${common.rootTarget.name}.target" ];
      after = [ "${common.backend}-${common.rootTarget.name}.target" ];
    };
  };
}
