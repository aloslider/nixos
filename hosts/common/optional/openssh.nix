{ config, ... }:
{
  services.openssh = {
    enable = true;
    ports = [ 6969 ];
    settings = {
      PasswordAuthentication = false;
      PermitEmptyPasswords = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
    };
  };
}
