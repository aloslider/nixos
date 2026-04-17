{ config, lib, ... }:
with lib;
let
  cfg = config.programs.git.options;
in
{
  options.programs.git.options = {
    username = mkOption {
      type = types.str;
      default = "aloslider";
    };
    email = mkOption {
      type = types.str;
      default = "53711835+aloslider@users.noreply.github.com";
    };
  };

  config = {
    programs.git = {
      settings = {
        user = {
          name = cfg.username;
          email = cfg.email;
        };
        init.defaultBranch = "master";
      };
    };
  };
}
