{ config, ... }:
{
  imports = [
    ./network.nix
    ./containers
  ];
}
