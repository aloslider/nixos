{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    chezmoi
    lazygit
    lazydocker
  ];
}
