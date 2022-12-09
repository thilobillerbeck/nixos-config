{ config, pkgs, lib, ... }:
let
  gitea_url = "git.thilo-billerbeck.com";
  drone_url = "ci.thilo-billerbeck.com";
  drone_port = 4000;
  drone_proto = "https";
  secrets = import ./../../secrets/secrets.nix;
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ./modules/woodpecker-server.nix 
    ./modules/woodpecker-agent.nix 
    (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master") ];

  time.timeZone = "Europe/Berlin";

  system.stateVersion = "20.03";

  networking = {
    usePredictableInterfaceNames = false;
    enableIPv6 = true;
    interfaces.eth0.ipv6.addresses = [{
      address = "2a01:4f8:c2c:3c6e::1";
      prefixLength = 64;
    }];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    hostName = "bart";
    firewall.allowedTCPPorts = [ 22 80 443 9000 5000 ];
  };

  systemd = {
    timers = {
      gitea-backup-cleanup = {
        wantedBy = [ "timers.target" ];
        partOf = [ "gitea-backup-cleanup.service" ];
        timerConfig.OnCalendar = "daily";
      };
    };
    services = {
      restic-backups-remotebackup = {
        environment = {
          B2_ACCOUNT_KEY="${secrets.b2_backup.key}";
          B2_ACCOUNT_ID="${secrets.b2_backup.id}";
        };
      };
    };
    tmpfiles.rules = [
      "L+ '${config.services.gitea.stateDir}/custom/templates/home.tmpl' - - - - ${./gitea/gitea-home.tmpl}"
      "L+ '${config.services.gitea.stateDir}/custom/templates/custom/extra_links_footer.tmpl' - - - - ${./gitea/extra_links_footer.tmpl}"
      "L+ '${config.services.gitea.stateDir}/custom/public/css/theme-dark-fire.css' - - - - ${./gitea/theme-dark-fire.css}" 
    ];
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
          locations."/".proxyPass = "http://localhost:${toString config.services.gitea.httpPort}/";
        };
        "${drone_url}" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:3333";
        };
        "status.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:3002/";
            proxyWebsockets = true;
          };
        };
        "invoice.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          root = lib.mkForce "${pkgs.dolibarr}/htdocs";
          locations."/".index = "index.php";
          locations."~ [^/]\\.php(/|$)" = {
              extraConfig = ''
                fastcgi_split_path_info ^(.+?\.php)(/.*)$;
                fastcgi_pass unix:${config.services.phpfpm.pools.dolibarr.socket};
              '';
            };
          };
      };
    };
    dolibarr = {
      enable = true;
      domain = "invoice.thilo-billerbeck.com";
    };
    woodpecker-server = {
      enable = true;
      rootUrl = "https://ci.thilo-billerbeck.com";
      httpPort = 3333;
      admins = "thilobillerbeck";
      database = {
        type = "postgres";
      };
      giteaClientIdFile = /var/lib/secrets/woodpecker/giteClientId;
      giteaClientSecretFile = /var/lib/secrets/woodpecker/giteClientSecret;
      agentSecretFile = /var/lib/secrets/woodpecker/agentSecret;
    };
    woodpecker-agent = {
      enable = true;
      agentSecretFile = /var/lib/secrets/woodpecker/agentSecret;
    };
    vscode-server.enable = true;
    grocy = {
      enable = true;
      hostName = "grocy.thilo-billerbeck.com";
      settings = {
        currency = "EUR";
        culture = "de";
      };
    };
    gitea = {
      enable = true;
      cookieSecure = true;
      disableRegistration = true;
      httpPort = 3001;
      package = pkgs.gitea;
      appName = "Thilos SCM";
      rootUrl = "https://${gitea_url}/";
      lfs.enable = true;
      log.level = "Warn";
      mailerPasswordFile = "/var/lib/secrets/gitea/mailpw";
      database = {
        type = "postgres";
        passwordFile = "/var/lib/secrets/gitea/dbpw";
      };
      settings = {
        service = {
          REGISTER_EMAIL_CONFIRM = true;
          ENABLE_NOTIFY_MAIL = true;
          DEFAULT_KEEP_EMAIL_PRIVATE = true;
          DEFAULT_ALLOW_CREATE_ORGANIZATION = false;
          #explore = {
          #  DISABLE_USERS_PAGE = true;
          #};
        };
        "service.explore" = {
          DISABLE_USERS_PAGE = true;
        };
        federation = {
          ENABLED = true;
        };
        ui = {
          DEFAULT_THEME = "dark-fire";
          THEMES = "gitea,dark-fire";
          SHOW_USER_EMAIL = false;
        };
        indexer = { REPO_INDEXER_ENABLED = true; };
        mailer = {
          ENABLED = true;
          FROM = ''"Thilos Git" <git@officerent.de>'';
          MAILER_TYPE = "smtp";
          HOST = "mail.officerent.de:465";
          IS_TLS_ENABLED = true;
          USER = "git@officerent.de";
        };
      };
    };
    postgresql = {
      enable = true; # Ensure postgresql is enabled
      ensureDatabases = [ "woodpecker" "gitea" "keycloak" "ninja" ];
      ensureUsers = [
        {
          name = "woodpecker";
          ensurePermissions = { "DATABASE woodpecker" = "ALL PRIVILEGES"; };
        }
      ];
      identMap = # Map the gitea user to postgresql
        ''
          gitea-users gitea gitea
        '';
    };
    uptime-kuma = {
      enable = true;
      settings = {
        PORT = "3002";
      };
    };
    restic.backups = {
      remotebackup = {
        passwordFile = "/etc/nixos/secrets/restic-password";
        paths = [
          "${config.services.gitea.dump.backupDir}"
        ];
        extraOptions = [
          "B2_ACCOUNT_ID=''"
          "B2_ACCOUNT_KEY=''"
        ];
        repository = "b2:thilobillerbeck-backup:bart";
        timerConfig = {
          OnCalendar = "00:30";
          RandomizedDelaySec = "5h";
        };
      };
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
  };
}
