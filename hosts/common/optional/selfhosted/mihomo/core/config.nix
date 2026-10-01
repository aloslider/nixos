{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.mihomo;
  subUrl = config.sops.placeholder."mihomo/subscription_url";
  secret = config.sops.placeholder."mihomo/secret";
in
{
  config = mkIf rootCfg.enable {
    sops.templates."mihomo.yaml".content = ''
      mixed-port: 7890
      allow-lan: true
      bind-address: "*"
      mode: rule
      log-level: info
      ipv6: false
      external-controller: 0.0.0.0:9090
      secret: "${secret}"

      dns:
        enable: true
        listen: 0.0.0.0:1053
        nameserver:
          - 8.8.8.8
          - 1.1.1.1

      proxy-providers:
        sub:
          type: http
          url: "${subUrl}"
          interval: 3600
          path: ./providers/sub.yaml
          header:
            User-Agent:
              - "ClashMeta/1.19.30"
            x-hwid:
              - "homelab-mihomo"
            x-device-os:
              - "Linux"
            x-ver-os:
              - "NixOS"
            x-device-model:
              - "homelab"
          health-check:
            enable: true
            url: https://www.gstatic.com/generate_204
            interval: 300

      proxy-groups:
        - name: PROXY
          type: select
          use:
            - sub
          proxies:
            - DIRECT

        - name: AUTO
          type: url-test
          use:
            - sub
          url: https://www.gstatic.com/generate_204
          interval: 300

      rules:
        - DOMAIN-SUFFIX,nixos.org,PROXY
        - DOMAIN-SUFFIX,cache.nixos.org,PROXY
        - DOMAIN-SUFFIX,channels.nixos.org,PROXY
        - DOMAIN-SUFFIX,github.com,PROXY
        - DOMAIN-SUFFIX,githubusercontent.com,PROXY
        - MATCH,DIRECT
    '';
  };
}
