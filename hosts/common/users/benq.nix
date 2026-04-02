{
  config,
  lib,
  inputs,
  ...
}:
with lib;
{
  users = {
    mutableUsers = false;
    users.benq = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.benq-password.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAeIuJzR68xA4ugJjtWbwvaWEU852Hg9FAAhXNw8ou43 benq"
      ];
      extraGroups =
        let
        ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;
      in
        flatten [
        "wheel"
          (ifTheyExist [
           "docker"
           "git"
           "networkmanager"
           "video"
          ])
        ];
    };
  };
}
