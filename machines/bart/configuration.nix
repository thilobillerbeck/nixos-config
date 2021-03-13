{ config, pkgs, ... }:
let
  gitea_url = "git.thilo-billerbeck.com";
  drone_url = "ci.thilo-billerbeck.com";
  drone_port = 4000;
  drone_proto = "https";
  secrets = import ./../../secrets/secrets.nix;
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];

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
    firewall.allowedTCPPorts = [ 22 80 443 9001 ];
  };

  systemd.timers = {
    gitea-backup-cleanup = {
      wantedBy = [ "timers.target" ];
      partOf = [ "simple-timer.service" ];
      timerConfig.OnCalendar = "6h";
    };
  };

  systemd.services = {
    drone-server = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = [ ];
        Environment = [
          "DRONE_GITEA=true"
          "DRONE_GITEA_SERVER=https://${gitea_url}"
          "DRONE_GITEA_CLIENT_ID=${secrets.drone.gitea_client_id}"
          "DRONE_GITEA_CLIENT_SECRET=${secrets.drone.gitea_client_secret}"
          "DRONE_DATABASE_DATASOURCE=postgres:///droneserver?host=/run/postgresql"
          "DRONE_DATABASE_DRIVER=postgres"
          "DRONE_RPC_SECRET=${secrets.drone.rpc_secret}"
          "DRONE_SERVER_HOST=${drone_url}"
          "DRONE_SERVER_PORT=:${toString drone_port}"
          "DRONE_SERVER_PROTO=${drone_proto}"
          "DRONE_USER_CREATE=username:thilobillerbeck,admin:true"
        ];
        ExecStart = "${pkgs.drone}/bin/drone-server";
        User = "droneserver";
        Group = "droneserver";
      };
    };

    drone-agent = {
      wantedBy = [ "multi-user.target" ];
      # might break deployment
      restartIfChanged = true;
      serviceConfig = {
        Environment = [
          "DRONE_RPC_SECRET=${secrets.drone.rpc_secret}"
          "DRONE_RPC_HOST=${drone_url}"
          "DRONE_RPC_PROTO=${drone_proto}"
          "DRONE_SERBER_PORT=${toString drone_port}"
          "DRONE_SERVER=${drone_proto}://${drone_url}"
          "DRONE_RUNNER_CAPACITY=2"
          "DRONE_NAME=runner"
        ];
        EnvironmentFile = [ ];
        ExecStart = "${pkgs.drone}/bin/drone-agent";
        User = "drone-agent";
        Group = "drone-agent";
        SupplementaryGroups = [ "docker" ];
        DynamicUser = true;
      };
    };

    restic-backups-remotebackup = {
      environment = {
        B2_ACCOUNT_KEY="${secrets.b2_backup.key}";
        B2_ACCOUNT_ID="${secrets.b2_backup.id}";
      };
    };

    gitea-backup-cleanup = {
      serviceConfig.Type = "oneshot";
      script = ''
        find ${config.services.gitea.dump.backupDir}/* -mtime +3 -exec rm {} \;
      '';
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
        "${drone_url}" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:${toString drone_port}/";
        };
      };
    };
    gitea = {
      enable = true;
      cookieSecure = true;
      disableRegistration = true;
      httpPort = 3001;
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
      ensureDatabases = [ "droneserver" "gitea" ];
      ensureUsers = [{
        name = "droneserver";
        ensurePermissions = { "DATABASE droneserver" = "ALL PRIVILEGES"; };
      }];
      identMap = # Map the gitea user to postgresql
        ''
          gitea-users gitea gitea
        '';
    };
    prometheus = {
      enable = true;
      port = 9001;
      scrapeConfigs = [{
        job_name = "gitea_and_ci";
        static_configs = [{
          targets = [
            "127.0.0.1:${
              toString config.services.prometheus.exporters.node.port
            }"
          ];
        }];
      }];
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
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
      # extraOptions = "--add-runtime runsc=${pkgs.gvisor}/bin/runsc --default-runtime=runsc";
    };
  };
}

