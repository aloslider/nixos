{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    disko.url = "github:nix-community/disko";
    dotfiles = {
      url = "github:aloslider/dotfiles";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:mic92/sops-nix";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
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
            inherit (inputs) disko;
            lib = customLib;
          };
          modules = [
            ./hosts/homelab/configuration.nix
          ];
        };
      };
    };
}
