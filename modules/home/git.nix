{ config, ... }: {
	programs.git = {
		enable = true;
		settings = {
			user = {
				name  = "aloslider";
				email = "53711835+aloslider@users.noreply.github.com";
			};
			init.defaultBranch = "master";
		};
	};
}
