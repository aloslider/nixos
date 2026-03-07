{ config, pkgs, ... }: {
	users.users.benq = { 
		isNormalUser = true;
		extraGroups = [ "wheel" ];
	};

	home-manager = {
		useGlobalPkgs = true;
		useUserPackages = true;
		users.benq = { pkgs, ... }: {
			home.packages = with pkgs; [
				lazygit       
				lazydocker
			];
			home.stateVersion = "25.05";
		};
	};
											 }
