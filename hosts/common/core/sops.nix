{ config, inputs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = "/etc/sops/secrets.yaml";
    age.keyFile = "/etc/age/key.txt";
    validateSopsFiles = false;
    secrets = {
      benq-password = {
          neededForUsers = true;
      };
    };
  };
}
