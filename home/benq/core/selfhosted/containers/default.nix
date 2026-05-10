{ config, ... }:
let
  prefix = "sh-";
  cfg = config.selfhosted;
in
{
  imports = [
    ./common.nix

    ./homarr
    ./netbird
    ./pocket-id
    ./vaultwarden
  ];

  config.selfhosted = {
    common = {
      networkName = "selfhosted";
      dataDir = "/mnt/data";
    };
    homarr = {
      name = "${prefix}homarr";
      subdomain = "dash";
    };
    netbird =
      let
        nbPrefix = "${prefix}nb-";
      in
      {
        subdomain = "nb";
        traefik = {
          name = "${nbPrefix}traefik";
        };
        dashboard = {
          name = "${nbPrefix}dashboard";
        };
        server = {
          name = "${nbPrefix}server";
        };
        proxy = {
          name = "${nbPrefix}proxy";
        };
      };
    pocket-id = {
      name = "${prefix}pocket-id";
      subdomain = "id";
    };
    vaultwarden = {
      name = "${prefix}vaultwarden";
      subdomain = "vault";
    };
  };
}
