{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    extraSpecialArgs = {
      inherit (inputs) disko dotfiles sops-nix;
    };
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

        home.stateVersion = "25.05";
      };
  };
}
