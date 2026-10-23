{ config, lib, ... }:
with lib;
let
  cfg = config.selfhosted.turn;
  domain = "${config.sops.placeholder."domains/serv"}";
  realm = "${config.selfhosted.netbird.subdomain}.${domain}";
in
{
  config = mkIf cfg.enable {
    sops.secrets = {
      "turn/password" = { };
      "turn/public-ip" = { };
    };

    sops.templates."turnserver.conf" = {
      owner = "nobody";
      group = "nogroup";
      mode = "0400";
      restartUnits = [ "docker-turn-server.service" ];
      content = ''
        listening-port=${toString cfg.listenPort}
        listening-ip=${cfg.listenIP}
        fingerprint
        lt-cred-mech
        realm=${realm}
        user=turn:${config.sops.placeholder."turn/password"}
        min-port=${toString cfg.minPort}
        max-port=${toString cfg.maxPort}
        relay-ip=${cfg.listenIP}
        external-ip=${config.sops.placeholder."turn/public-ip"}/${cfg.listenIP}
        log-file=stdout
        no-cli
        no-tls
        no-dtls
      '';
    };
  };
}
