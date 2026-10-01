{ config, lib, ... }:
with lib;
let
  rootCfg = config.selfhosted.mail;
  cfg = rootCfg.stalwart;
  domain = config.sops.placeholder."domains/serv";
  pocketIdSubdomain = config.selfhosted.pocket-id.subdomain;
  adminPassword = config.sops.placeholder."stalwart/admin_password";
in
{
  config = mkIf rootCfg.enable {
    sops.templates."stalwart.env".content = ''
      STALWART_PUBLIC_URL=https://${cfg.subdomain}.${domain}
      STALWART_RECOVERY_MODE=0
      STALWART_RECOVERY_ADMIN=admin:${adminPassword}
    '';

    sops.templates."stalwart-cli.env".content = ''
      STALWART_URL=http://127.0.0.1:${toString cfg.hostHttpPort}
      STALWART_USER=admin
      STALWART_PASSWORD="${adminPassword}"
    '';

    sops.templates."stalwart-config.json".content = ''
      {
        "@type": "RocksDb",
        "path": "/var/lib/stalwart/"
      }
    '';

    sops.templates."stalwart-oidc-plan.json".content = ''
      [
        {
          "@type": "upsert",
          "object": "DnsServer",
          "matchOn": ["description"],
          "value": {
            "dns-porkbun": {
              "@type": "Porkbun",
              "description": "Porkbun",
              "apiKey": "${config.sops.placeholder."porkbun/serv/api_key"}",
              "secretApiKey": {
                "@type": "Value",
                "secret": "${config.sops.placeholder."porkbun/serv/secret_key"}"
              },
              "timeout": 30000,
              "ttl": 300000,
              "pollingInterval": 15000,
              "propagationTimeout": 120000,
              "propagationDelay": 15000
            }
          }
        },
        {
          "@type": "upsert",
          "object": "AcmeProvider",
          "matchOn": ["directory", "challengeType"],
          "value": {
            "acme-letsencrypt": {
              "directory": "https://acme-v02.api.letsencrypt.org/directory",
              "challengeType": "Dns01",
              "contact": {
                "${config.sops.placeholder."letsEncrypt/email"}": true
              },
              "renewBefore": "R23",
              "maxRetries": 10
            }
          }
        },
        {
          "@type": "upsert",
          "object": "Directory",
          "matchOn": ["issuerUrl"],
          "value": {
            "dir-oidc": {
              "@type": "Oidc",
              "description": "Pocket-ID",
              "issuerUrl": "https://${pocketIdSubdomain}.${domain}",
              "requireAudience": null,
              "requireScopes": {},
              "claimUsername": "preferred_username",
              "usernameDomain": "${domain}",
              "claimName": "name",
              "claimGroups": null
            }
          }
        },
        {
          "@type": "upsert",
          "object": "Domain",
          "matchOn": ["name"],
          "value": {
            "dom-mail": {
              "name": "${domain}",
              "isEnabled": true,
              "directoryId": "#dir-oidc",
              "subAddressing": {
                "@type": "Enabled"
              },
              "certificateManagement": {
                "@type": "Automatic",
                "acmeProviderId": "#acme-letsencrypt",
                "subjectAlternativeNames": {
                  "${cfg.subdomain}": true
                }
              },
              "dkimManagement": {
                "@type": "Automatic"
              },
              "dnsManagement": {
                "@type": "Automatic",
                "dnsServerId": "#dns-porkbun",
                "origin": "${domain}",
                "publishRecords": {
                  "autoConfig": true,
                  "autoConfigLegacy": true,
                  "autoDiscover": true,
                  "caa": true,
                  "dkim": true,
                  "dmarc": true,
                  "mtaSts": true,
                  "mx": true,
                  "spf": true,
                  "srv": true,
                  "tlsRpt": true
                }
              }
            }
          }
        },
        {
          "@type": "upsert",
          "object": "AllowedIp",
          "matchOn": ["address"],
          "value": {
            "allow-netbird-cgnat": {
              "address": "100.64.0.0/10",
              "reason": "NetBird reverse-proxy and peers (CGNAT)"
            }
          }
        },
        {
          "@type": "update",
          "object": "SystemSettings",
          "value": {
            "defaultDomainId": "#dom-mail",
            "defaultHostname": "${cfg.subdomain}.${domain}"
          }
        },
        {
          "@type": "update",
          "object": "Authentication",
          "value": {
            "directoryId": "#dir-oidc"
          }
        }
      ]
    '';
  };
}
