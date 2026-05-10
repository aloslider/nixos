{ congif, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    age
    bind
    btop
    git
    jq
    openssl
    tmux
    tree
  ];
}
