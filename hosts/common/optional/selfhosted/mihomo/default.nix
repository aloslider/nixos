{
  config,
  lib,
  ...
}:
with lib;
let
  common = config.selfhosted.common;
  cfg = config.selfhosted.mihomo;
in
{
  imports = [
    ./core
    ./dashboard
  ];

  options.selfhosted.mihomo = {
    enable = mkEnableOption "Enable ${cfg.targetName} root target";
    targetName = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "mihomo/subscription_url" = { };
      "mihomo/secret" = { };
    };

    systemd.targets."${common.backend}-${cfg.targetName}" = {
      unitConfig = {
        Description = "Root target for ${cfg.targetName}";
      };
      wantedBy = [ "${common.backend}-${common.rootTarget.name}.target" ];
      partOf = [ "${common.backend}-${common.rootTarget.name}.target" ];
      after = [ "${common.backend}-${common.rootTarget.name}.target" ];
    };

    # set proxy for build time
    systemd.services.nix-daemon =
      let
        mihomoService = "${common.backend}-${cfg.core.name}.service";
        socksPort = "${toString cfg.core.hostMixedPort}";
      in
      {
        after = [ "${mihomoService}" ];
        environment = {
          http_proxy = "http://127.0.0.1:${socksPort}";
          https_proxy = "http://127.0.0.1:${socksPort}";
          HTTP_PROXY = "http://127.0.0.1:${socksPort}";
          HTTPS_PROXY = "http://127.0.0.1:${socksPort}";
          ALL_PROXY = "socks5h://127.0.0.1:${socksPort}";
          NO_PROXY = "localhost,127.0.0.1,::1";
          no_proxy = "localhost,127.0.0.1,::1";
        };
      };
  };
}
