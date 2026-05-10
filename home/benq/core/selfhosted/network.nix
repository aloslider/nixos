{ config, ... }:
let
  common = config.selfhosted.common;
in
{
  services.podman = {
    networks.${common.networkName} = {
      driver = "bridge";
    };
  };
}
