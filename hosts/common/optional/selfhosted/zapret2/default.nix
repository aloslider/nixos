{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.zapret2;
in
{
  options.selfhosted.zapret2 = {
    name = mkOption {
      type = types.str;
    };
    socksPort = mkOption {
      type = types.port;
    };
    ssPort = mkOption {
      type = types.port;
    };
  };

  config =
    let
      socksPort = "${toString cfg.socksPort}";
      ssPort = "${toString cfg.ssPort}";
      configFiles = import ./config.nix { inherit pkgs; };
    in
    {
      virtualisation.oci-containers.containers.${cfg.name} = {
        image = "vernette/ss-zapret2:latest";
        volumes = [
          "${configFiles.config}:/opt/zapret2/config"
        ];
        environment = {
          SOCKS_PORT = socksPort;
          SS_PORT = ssPort;
          SS_PASSWORD = "test";
          SS_ENCRYPT_METHOD = "chacha20-ietf-poly1305";
          SS_TIMEOUT = "300";
        };
        ports = [
          "127.0.0.1:${socksPort}:${socksPort}"
          "127.0.0.1:${ssPort}:${ssPort}"
        ];
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--network=host"
        ];
      };

      systemd.services."${common.backend}-${cfg.name}" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
        };
        postStart = ''
            mv /opt/zapret2/lua.dist /opt/zapret2/lua || true
        '';
        after = [ "${common.backend}-network-${common.network.name}.service" ];
        requires = [ "${common.backend}-network-${common.network.name}.service" ];
        partOf = [ "${common.backend}-${common.rootTarget.name}.target" ];
        wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
      };
    };
}
