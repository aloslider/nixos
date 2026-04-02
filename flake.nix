{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:mic92/sops-nix";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs;
    customLib = pkgs.lib.extend (
      self: super: {
        custom = (
          import ./lib {
            inherit (pkgs) lib;
          }
        );
      }
    );
  in
  {
    nixosConfigurations = {
      homelab = pkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          lib = customLib;
        };
        modules = [
          ./hosts/homelab/configuration.nix
        ];
      };
    };
  };
}
