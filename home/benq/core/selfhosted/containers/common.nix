{ config, lib, ... }:
with lib;
{
  options.selfhosted.common = {
    networkName = mkOption {
      type = types.str;
    };
    dataDir = mkOption {
      type = types.str;
    };
  };

  config = {
    sops.secrets = {
      "domains/serv" = { };
    };
  };
}
