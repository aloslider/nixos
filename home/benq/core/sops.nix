{ config, dotfiles, sops-nix, ... }:
{
  imports = [
    sops-nix.homeManagerModules.sops
  ];

  sops = {
    defaultSopsFile = "${dotfiles}/dot_config/sops/secrets.yaml";
    age.keyFile = "${config.xdg.configHome}/age/key.txt";
  };

  home.file.".sops.yaml".source = "${dotfiles}/dot_sops.yaml";

  xdg.configFile."sops" = {
    source = "${dotfiles}/dot_config/sops";
    recursive = true;
  };
}
