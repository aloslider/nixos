{ config, pkgs, ... }: {
	virtualisation.docker = {
		enable = true;
		rootless = {
			enable = true;
			setSocketVariable = true;
		};
	};
	security.wrappers = {
		docker-rootlesskit = {
			owner = "root";
			group = "root";
			capabilities = "cap_net_bind_service+ep";
			source = "${pkgs.rootlesskit}/bin/rootlesskit";
		};
	};
}	
