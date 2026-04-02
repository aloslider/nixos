{ config, ... }:
{
  imports = [
    ./disko.nix
    ./locale.nix
    ./nix.nix
    ./packages.nix
    ./sops.nix
  ];
}
