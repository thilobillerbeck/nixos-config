{ config, pkgs, ... }:
let
  gitea_url = "git.thilo-billerbeck.com";
  drone_url = "ci.thilo-billerbeck.com";
  drone_port = 4000;
  drone_proto = "https";
  secrets = import ./../../secrets/secrets.nix;
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];

  nixpkgs.config.allowUnfree = true;

  system = {
    autoUpgrade.allowReboot = true;
    stateVersion = "20.03";
  };

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
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

  systemd.timers = {
    gitea-backup-cleanup = {
      wantedBy = [ "timers.target" ];
      partOf = [ "gitea-backup-cleanup.service" ];
      timerConfig.OnCalendar = "daily";
    };
  };

  systemd.services = {
    restic-backups-remotebackup = {
      environment = {
        B2_ACCOUNT_KEY="${secrets.b2_backup.key}";
        B2_ACCOUNT_ID="${secrets.b2_backup.id}";
      };
    };

    gitea-backup-cleanup = {
      serviceConfig.Type = "oneshot";
      script = ''
         ls -td ${config.services.gitea.dump.backupDir}/* | tail -n +1 | xargs -I {} rm {}
      '';
    };
  };

  virtualisation.oci-containers.containers = {
    watchtower = {
      image = "containrrr/watchtower:latest";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    };
    uptimekuma = {
      image = "louislam/uptime-kuma:1";
      ports = ["3002:3001"];
      volumes = [
        "/var/lib/uptimekuma:/app/data"
      ];
    };
  };

  users = {
    users.droneserver = {
      isSystemUser = true;
      createHome = true;
      group = "droneserver";
    };
    groups.droneserver = { };
  };

  time.timeZone = "Europe/Berlin";

  services = {
    openssh = { enable = true; };
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
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
      package = unstable.gitea;
      appName = "Thilos SCM";
      rootUrl = "https://${gitea_url}/";
      log.level = "Warn";
      mailerPasswordFile = "/var/lib/secrets/gitea/mailpw";
      dump.enable = true;
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
        };
        ui = {
          DEFAULT_THEME = "arc-green";
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
      ensureDatabases = [ "droneserver" "gitea" "keycloak" ];
      ensureUsers = [
        {
          name = "droneserver";
          ensurePermissions = { "DATABASE droneserver" = "ALL PRIVILEGES"; };
        }
        {
          name = "keycloak";
          ensurePermissions = { "DATABASE keycloak" = "ALL PRIVILEGES"; };
        }
      ];
      identMap = # Map the gitea user to postgresql
        ''
          gitea-users gitea gitea
        '';
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
  security.acme = {
    email = "thilo.billerbeck@officerent.de";
    acceptTerms = true;
  };
}

