{ config, ... }:
{
  imports = [
    ./disko.nix
    ./locale.nix
    ./netbird.nix
    ./nix.nix
    ./packages.nix
    ./sops.nix
    ./zsh.nix
  ];
}
