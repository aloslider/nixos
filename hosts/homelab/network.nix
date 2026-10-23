{ config, lib, ... }:
{
  networking = {
    hostName = "homelab";
    firewall = {
      allowedTCPPorts = [
        22
        80
        443
        2222
        6969
      ]
      ++ [
        config.selfhosted.mihomo.core.hostApiPort
      ]
      ++ config.selfhosted.mail.hostPorts;
      allowedUDPPorts = [
        3478
        7359
        51820
      ]
      ++ lib.optionals config.selfhosted.turn.enable [
        config.selfhosted.turn.listenPort
      ];
      allowedTCPPortRanges = lib.optionals config.selfhosted.mirotalk.enable [
        {
          from = config.selfhosted.mirotalk.server.minPort;
          to = config.selfhosted.mirotalk.server.maxPort;
        }
      ];
      allowedUDPPortRanges = lib.optionals config.selfhosted.turn.enable [
        {
          from = config.selfhosted.turn.minPort;
          to = config.selfhosted.turn.maxPort;
        }
      ]
      ++ lib.optionals config.selfhosted.mirotalk.enable [
        {
          from = config.selfhosted.mirotalk.server.minPort;
          to = config.selfhosted.mirotalk.server.maxPort;
        }
      ];
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 80;
  };
}
