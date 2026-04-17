{ config, ... }:
{
  networking = {
    hostName = "homelab";
    useDHCP = false;
    dhcpcd.enable = false;
    defaultGateway = "192.168.88.1";
    nameservers = [ "192.168.88.1" ];

    interfaces.enp7s0.ipv4.addresses = [
    {
      address = "192.168.88.5";
      prefixLength = 24;
    }
    ];

    firewall = {
      allowedTCPPorts = [
        22
        80
        443
      ];
      allowedUDPPorts = [ ];
    };
  };
}
