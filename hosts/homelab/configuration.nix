{
  config,
  lib,
  ...
}:
{
  imports = lib.flatten [
    ./boot.nix
    ./network.nix
    ./hardware-configuration.nix
    (map lib.custom.relativeToRoot (
      [
        "hosts/common/core"
        "hosts/common/users/benq.nix"
        "home/benq/homelab.nix"
      ]
      ++ (map (f: "hosts/common/optional/${f}") [
        "bbr.nix"
        "docker.nix"
        "endlessh.nix"
        "fail2ban.nix"
        "openssh.nix"
      ])
    ))
  ];

  disko.cfg.mainDevice = "/dev/disk/by-id/ata-AMD_R5M120G8_07092225C0040";
  system.stateVersion = "26.05";
}
