{ config, ... }:
{
  networking = {
    hostName = "homelab";
    useDHCP = false;
    networkmanager.enable = false;
  };

  systemd.network = {
    enable = true;
    networks."10-homelab-static-ip" = {
      networkConfig = {
        Address = "192.168.88.5/24";
        Gateway = "192.168.88.1";
        DNS = [ "192.168.88.1" ];
      };
      matchConfig.Name = "enp1s0";
      linkConfig.RequiredForOnline = "routable";
      firewall = {
        allowedTCPPorts = [
          22
          80
          443
        ];
        allowedUDPPorts = [ ];
      };
    };
  };
}
