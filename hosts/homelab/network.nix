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
      allowedUDPPortRanges = lib.optionals config.selfhosted.turn.enable [
        {
          from = config.selfhosted.turn.minPort;
          to = config.selfhosted.turn.maxPort;
        }
      ];
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 80;
  };
}
