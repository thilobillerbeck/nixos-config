{ config, pkgs, lib, ... }:

let
  gitea_url = "git.thilo-billerbeck.com";
  drone_url = "ci.thilo-billerbeck.com";
  drone_port = 4000;
  drone_proto = "https";
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable {
    config.allowUnfree = true;
    system = "aarch64-linux";
  };
in {
  imports = [
    ./../../configs/server.nix
    ./hardware.nix
    ./../../modules/woodpecker-agent.nix
    ./../../modules/colmena-upgrade.nix
    ./../../users/deploy.nix
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
    firewall.allowedTCPPorts = [ 22 80 443 9001 ];
  };

  systemd = {
    timers = {
      gitea-backup-cleanup = {
        wantedBy = [ "timers.target" ];
        partOf = [ "gitea-backup-cleanup.service" ];
        timerConfig.OnCalendar = "daily";
      };
    };
    tmpfiles.rules = [
      "L+ '${config.services.gitea.stateDir}/custom/templates/home.tmpl' - - - - ${
        ./gitea/gitea-home.tmpl
      }"
      "L+ '${config.services.gitea.stateDir}/custom/templates/custom/extra_links_footer.tmpl' - - - - ${
        ./gitea/extra_links_footer.tmpl
      }"
      "L+ '${config.services.gitea.stateDir}/custom/public/css/theme-dark-fire.css' - - - - ${
        ./gitea/theme-dark-fire.css
      }"
      "L+ '${config.services.gitea.stateDir}/custom/public/img/logo.svg' - - - - ${
        ./gitea/logo.svg
      }"
      "L+ '${config.services.gitea.stateDir}/custom/public/img/favicon.png' - - - - ${
        ./gitea/favicon.png
      }"
    ];
  };

  age.secrets = {
    giteaMailerPassword = {
      file = ./../../secrets/giteaMailerPassword.age;
      owner = "gitea";
      group = "gitea";
    };
    giteaDatabasePassword = {
      file = ./../../secrets/giteaDatabasePassword.age;
      owner = "gitea";
      group = "gitea";
    };
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
        "${drone_url}" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:3333";
        };
        "officerent.de" = {
          enableACME = true;
          forceSSL = true;
          root = "/var/www/officerent.de";
          serverAliases = [
            "www.officerent.de"
          ];
        };
        "thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          root = "/var/www/thilo-billerbeck.com";
          serverAliases = [
            "www.thilo-billerbeck.com"
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
      };
    };
    gitea = {
      enable = true;
      cookieSecure = true;
      disableRegistration = true;
      httpPort = 3001;
      package = unstable.forgejo;
      appName = "Thilos SCM";
      rootUrl = "https://${gitea_url}/";
      lfs.enable = true;
      log.level = "Debug";
      mailerPasswordFile = config.age.secrets.giteaMailerPassword.path;
      database = {
        type = "postgres";
        passwordFile = config.age.secrets.giteaDatabasePassword.path;
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
        "service.explore" = { DISABLE_USERS_PAGE = true; };
        federation = { ENABLED = true; };
        ui = {
          # DEFAULT_THEME = "dark-fire";
          # THEMES = "gitea,dark-fire";
          SHOW_USER_EMAIL = false;
        };
        indexer = { REPO_INDEXER_ENABLED = true; };
        actions = { ENABLED = true; };
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
      ensureDatabases = [ "woodpecker" "gitea" ];
      ensureUsers = [{
        name = "woodpecker";
        ensurePermissions = { "DATABASE woodpecker" = "ALL PRIVILEGES"; };
      }];
      identMap = # Map the gitea user to postgresql
        ''
          gitea-users gitea gitea
        '';
    };
    uptime-kuma = {
      enable = true;
      package = unstable.uptime-kuma;
      settings = { PORT = "3002"; };
    };
    prometheus = {
      enable = true;
      port = 9001;
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
      };
      scrapeConfigs = [
        {
          job_name = "bart";
          static_configs = [{
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }];
        }
      ];
    };
  };
}
