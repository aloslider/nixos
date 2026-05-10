{ config, ... }:
{
  networking = {
    hostName = "homelab";
    firewall = {
      allowedTCPPorts = [ 22 80 443 6969 ];
      allowedUDPPorts = [ 3478 ];
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 80;
  };
}
