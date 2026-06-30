{ congif, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    age
    bat
    bind
    btop
    git
    jq
    openssl
    ripgrep
    tmux
    tree
    vim
    wget
  ];
}
