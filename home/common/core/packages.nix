{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    chezmoi
    fzf
    lazygit
    lazydocker
    sops
  ];
}
