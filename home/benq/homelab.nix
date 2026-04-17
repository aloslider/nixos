{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.benq =
      { pkgs, ... }:
      {
        imports = lib.flatten [
          (map lib.custom.relativeToRoot (
            [
              "home/benq/core"
            ]
            ++ (map (f: "home/benq/optional/${f}") [
            ])
          ))
        ];

        home.packages = with pkgs; [
          chezmoi
          lazygit
          lazydocker
        ];
        home.stateVersion = "25.05";
      };
  };
}
