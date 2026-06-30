{ config, ... }:
{
  imports = [
    ./git.nix
    ./packages.nix
    # ./sops.nix
  ];
}
