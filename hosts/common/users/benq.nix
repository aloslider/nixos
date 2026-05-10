{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  users = {
    mutableUsers = false;
    users.benq = {
      shell = pkgs.zsh;
      isNormalUser = true;
      ignoreShellProgramCheck = true;
      hashedPasswordFile = config.sops.secrets.benq-password.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAeIuJzR68xA4ugJjtWbwvaWEU852Hg9FAAhXNw8ou43 benq"
      ];
      linger = true;
      subUidRanges = [ { startUid = 100000; count = 65536; } ];
      subGidRanges = [ { startGid = 100000; count = 65536; } ];
      extraGroups =
        let
        ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;
      in
        flatten [
        "wheel"
          (ifTheyExist [
           "git"
           "networkmanager"
           "video"
          ])
        ];
    };
  };
}
