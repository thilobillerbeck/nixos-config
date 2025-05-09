{ config, pkgs, lib, ... }:

with builtins;
let
  gitea_url = "git.thilo-billerbeck.com";
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable {
    config.allowUnfree = true;
    system = "aarch64-linux";
  };
  deployHookShellScript = pkgs.writeShellApplication {
    name = "deploy-skymoth-hook";

    runtimeInputs = with pkgs; [ git docker openssh ];
    text = ''
      git pull
      docker compose up --build -d
    '';
  };
  thiloBillerbeckComDeployScript = pkgs.writeShellApplication {
    name = "deploy-thilo-billerbeck.com-hook";

    runtimeInputs = with pkgs; [ curl unzip rsync ];

    text = ''
      mkdir -p /tmp/thilo-billerbeck.com
      curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $2" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/thilobillerbeck/thilo-billerbeck-com/actions/artifacts/$1/zip" > /tmp/thilo-billerbeck.com/artifact.zip
      unzip -o /tmp/thilo-billerbeck.com/artifact.zip -d /tmp/thilo-billerbeck.com
      rm /tmp/thilo-billerbeck.com/artifact.zip
      rsync -avzr --delete --omit-dir-times --no-perms /tmp/thilo-billerbeck.com/ /var/www/thilo-billerbeck.com/
      rm -rf /tmp/thilo-billerbeck.com
    '';
  };
in
{
  imports = [
    ./../../configs/server.nix
    ./hardware.nix
    ./../../users/deploy.nix
    ./../../modules/deploymentUser.nix
    ./../../private/machines/bart.nix
  ];

  time.timeZone = "Europe/Berlin";

  system.stateVersion = "20.03";

  networking = {
    usePredictableInterfaceNames = false;
    enableIPv6 = true;
    interfaces.eth0.ipv6.addresses = [{
      address = "2a01:4f8:c17:21a4::1";
      prefixLength = 64;
    }];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    hostName = "bart";
    firewall.allowedTCPPorts = [ 22 80 443 5001 9002 ];
  };

  systemd = {
    services.webhook = {
      serviceConfig.EnvironmentFile = config.age.secrets.webhooksecret.path;
    };
    tmpfiles.rules = [
      "L+ '${config.services.forgejo.customDir}/templates/home.tmpl' - forgejo forgejo - ${
        ./gitea/gitea-home.tmpl
      }"
      "L+ '${config.services.forgejo.customDir}/templates/custom/extra_links_footer.tmpl' - forgejo forgejo - ${
        ./gitea/extra_links_footer.tmpl
      }"
      "L+ '${config.services.forgejo.customDir}/public/img/logo.svg' - forgejo forgejo - ${
        ./gitea/logo.svg
      }"
      "L+ '${config.services.forgejo.customDir}/public/img/favicon.png' - forgejo forgejo - ${
        ./gitea/favicon.png
      }"
    ];
  };

  age.secrets = {
    giteaMailerPassword = {
      file = ./../../private/secrets/giteaMailerPassword.age;
      owner = "forgejo";
      group = "forgejo";
    };
    giteaDatabasePassword = {
      file = ./../../private/secrets/giteaDatabasePassword.age;
      owner = "forgejo";
      group = "forgejo";
    };
    resticBackupPassword = { file = ./../../private/secrets/resticBackupPassword.age; };
    burnsBackupEnv = { file = ./../../private/secrets/burnsBackupEnv.age; };
    webhooksecret = { file = ./../../private/secrets/webhooksecret.age; };
  };

  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "${gitea_url}" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass =
            "http://localhost:${toString config.services.gitea.httpPort}/";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
        "officerent.de" = {
          enableACME = true;
          forceSSL = true;
          serverAliases = [
            "www.officerent.de"
          ];
          locations."/".return = "301 https://thilo-billerbeck.com$request_uri";
        };
        "thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          root = "/var/www/thilo-billerbeck.com";
          serverAliases = [
            "www.thilo-billerbeck.com"
          ];
        };
        "rww-wiki.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          root = "/var/www/rww-wiki.thilo-billerbeck.com";
          basicAuthFile = "/var/lib/secrets/rww-wiki-auth";
          serverAliases = [
            "wiki.radio-wein-welle.de"
          ];
        };
        "status.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:3002/";
            proxyWebsockets = true;
          };
        };
        "bart.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:9000/";
          };
        };
        "skymoth.app" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyWebsockets = true;
            proxyPass = "http://localhost:5555";
          };
        };
        "invoice.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:3003/";
            proxyWebsockets = true;
          };
        };
        "audiobookshelf.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://docker01:13378";
            proxyWebsockets = true;
          };
        };
        "photos.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://flanders:2283";
            proxyWebsockets = true;
          };
        };
      };
    };
    forgejo = {
      enable = true;
      cookieSecure = true;
      disableRegistration = true;
      package = unstable.forgejo;
      appName = "Thilos SCM";
      rootUrl = "https://${gitea_url}/";
      lfs.enable = true;
      dump = {
        enable = true;
        file = "forgejo-dump";
        interval = "02:30";
      };
      mailerPasswordFile = config.age.secrets.giteaMailerPassword.path;
      database = {
        type = "postgres";
        createDatabase = true;
        passwordFile = config.age.secrets.giteaDatabasePassword.path;
      };
      settings = {
        service = {
          REGISTER_EMAIL_CONFIRM = true;
          ENABLE_NOTIFY_MAIL = true;
          DEFAULT_KEEP_EMAIL_PRIVATE = true;
          DEFAULT_ALLOW_CREATE_ORGANIZATION = false;
          HTTP_PORT = 3001;
          DOMAIN = "git.thilo-billerbeck.com";
        };
        "service.explore" = { DISABLE_USERS_PAGE = true; };
        federation = { ENABLED = true; };
        ui = {
          SHOW_USER_EMAIL = false;
        };
        indexer = { REPO_INDEXER_ENABLED = true; };
        actions = { ENABLED = true; };
        mailer = {
          ENABLED = true;
          FROM = ''"Thilos Git" <git@officerent.de>'';
          PROTOCOL = "smtp";
          HOST = "mail.officerent.de:465";
          IS_TLS_ENABLED = true;
          USER = "git@officerent.de";
        };
        "repository.upload" = {
          TEMP_PATH = "/tmp/gitea/uploads";
        };
      };
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
    };
    uptime-kuma = {
      enable = true;
      package = unstable.uptime-kuma;
      settings = { PORT = "3002"; };
    };
    prometheus = {
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
      };
    };
    restic.backups.bart = {
      initialize = true;
      passwordFile = config.age.secrets.resticBackupPassword.path;
      environmentFile = config.age.secrets.burnsBackupEnv.path;
      paths = [
        "/var/lib/forgejo/dump"
        "/opt/stacks/invoiceninja/docker"
      ];
      repository = "b2:backup-bart";
      timerConfig = { OnCalendar = "*-*-* 3:00:00"; };
      pruneOpts = [ "--keep-daily 5" ];
    };
    webhook = {
      enable = true;
      user = "deploy";
      group = "deploy";
      hooksTemplated = {
        thilo-billerbeck-com-deploy = ''
          {
            "id": "thilo-billerbeck-com-deploy",
            "execute-command": "${thiloBillerbeckComDeployScript}/bin/deploy-thilo-billerbeck.com-hook",
            "include-command-output-in-response": true,
            "include-command-output-in-response-on-error": true,
            "pass-arguments-to-command":
            [
              {
                "source": "url",
                "name": "artifact"
              },
              {
                "source": "string",
                "name": "{{ getenv "GITHUB_TOKEN" | js }}"
              },
            ],
            "trigger-rule":
            {
              "match":
              {
                "type": "value",
                "value": "{{ getenv "WEBHOOK_SECRET" | js }}",
                "parameter":
                {
                  "source": "url",
                  "name": "token"
                }
              }
            }
          }
        '';
        skymoth-deploy = ''
          {
            "id": "skymoth-deploy",
            "execute-command": "${deployHookShellScript}/bin/deploy-skymoth-hook",
            "command-working-directory": "/opt/stacks/skymoth",
            "include-command-output-in-response": true,
            "include-command-output-in-response-on-error": true,
            "trigger-rule":
            {
              "match":
              {
                "type": "value",
                "value": "{{ getenv "WEBHOOK_SECRET" | js }}",
                "parameter":
                {
                  "source": "url",
                  "name": "token"
                }
              }
            }
          }
        '';
      };
    };
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
      openFirewall = true;
    };
  };
  users.deploymentUsers .rww-wiki = {
    deploymentPath = "/var/www/rww-wiki.thilo-billerbeck.com";
    keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgpdAnTQh8EF2Ehga5LDaJWyMrv6pwv7BddF2jgRXQn rww-wiki@github"
    ];
  };
  virtualisation = {
    docker = {
      enable = true;
    };
  };
}
