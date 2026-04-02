{ config, ... }:
{
  services.endlessh = {
    enable = true;
    port = 22;
    openFirewall = true;
  };

  systemd.services.endlessh = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
  };
}
