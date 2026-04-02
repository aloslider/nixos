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
          ./packages.nix
          (map (f: lib.custom.relativeToRoot "home/common/optional/${f}") [
            "git.nix"
          ])
        ];

        home.stateVersion = "25.05";
      };
  };
}
