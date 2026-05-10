{ config, ... }:
{
  imports = [
    ./git.nix
    ./packages.nix
    ./podman.nix
    ./selfhosted
    ./sops.nix
  ];
}
