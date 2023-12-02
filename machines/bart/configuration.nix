{ config, pkgs, lib, ... }:

let
  gitea_url = "git.thilo-billerbeck.com";
  drone_url = "ci.thilo-billerbeck.com";
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable {
    config.allowUnfree = true;
    system = "aarch64-linux";
  };
in
{
  imports = [
    ./../../configs/server.nix
    ./hardware.nix
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
    firewall.allowedTCPPorts = [ 22 80 443 5001 9002 ];
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
      file = ./../../secrets/giteaMailerPassword.age;
      owner = "forgejo";
      group = "forgejo";
    };
    giteaDatabasePassword = {
      file = ./../../secrets/giteaDatabasePassword.age;
      owner = "forgejo";
      group = "forgejo";
    };
    resticBackupPassword = { file = ./../../secrets/resticBackupPassword.age; };
    burnsBackupEnv = { file = ./../../secrets/burnsBackupEnv.age; };
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
        "obsync.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:3000/";
            proxyWebsockets = true;
          };
        };
        "status.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:3002/";
            proxyWebsockets = true;
          };
        };
        "zsh-sl-api.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:5675/";
            proxyWebsockets = true;
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
      package = pkgs.postgresql;
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
      ];
      repository = "b2:backup-bart";
      timerConfig = { OnCalendar = "*-*-* 3:00:00"; };
      pruneOpts = [ "--keep-daily 5" ];
    };
  };
  virtualisation = {
    docker = {
      enable = true;
    };
  };
}
