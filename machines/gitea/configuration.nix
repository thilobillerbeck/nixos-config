{ config, pkgs, ... }:
let gitea_url = "git.thilo-billerbeck.com";
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];

  system = {
    autoUpgrade.allowReboot = true;
    stateVersion = "20.03";
  };
	
  nix.gc.automatic = true;

  networking.usePredictableInterfaceNames = false;
  networking = {
    enableIPv6 = true;
    interfaces.eth0.ipv6.addresses = [ {
      address = "2a01:4f8:c2c:3c6e::1";
      prefixLength = 64;
    } ];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    hostName = "gitea";
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

    systemd.services.drone-server = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = [ ];
        Environment = [
          "DRONE_GITEA=true"
          "DRONE_GITEA_SERVER=https://${gitea_url}";
          "DRONE_GITEA_CLIENT_ID=146c9b07-8c10-40c3-8cf4-e391258a6768";
          "DRONE_GITEA_CLIENT_SECRET=_48BPPhEFm-OJlbJRbXoKM1swcs_PStXJlKOUPPsuiU=";
          "DRONE_RPC_SECRET=65e33f4b929df4e4efcb00859e504e8d";
          "DRONE_SERVER_HOST=ci.thilo-billerbeck.com";
          "DRONE_SERVER_PORT=:4000"
          "DRONE_SERVER_PROTO=https";
          "DRONE_USER_CREATE=username:thilobillerbeck,admin:true";
        ];
        ExecStart = "${pkgs.drone}/bin/drone-server";
        User = thilo;
        Group = thilo;
      };
    };

  systemd.services.drone-agent = {
    wantedBy = [ "multi-user.target" ];
    # might break deployment
    restartIfChanged = true;
    serviceConfig = {
      Environment = [
        "DRONE_RPC_SECRET=65e33f4b929df4e4efcb00859e504e8d"
        "DRONE_RPC_HOST=ci.thilo-billerbeck.com"
        "DRONE_RPC_PROTO=https"
        "DRONE_SERBER_PORT=4000"
        "DRONE_SERVER=https://ci.thilo-billerbeck.com"
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

  virtualisation.oci-containers.containers = {
    "drone" = {
      image = "drone/drone:1";
      environment = {
        "DRONE_GITEA_SERVER" = "https://${gitea_url}";
        "DRONE_GITEA_CLIENT_ID" = "146c9b07-8c10-40c3-8cf4-e391258a6768";
        "DRONE_GITEA_CLIENT_SECRET" =
          "_48BPPhEFm-OJlbJRbXoKM1swcs_PStXJlKOUPPsuiU=";
        "DRONE_RPC_SECRET" = "65e33f4b929df4e4efcb00859e504e8d";
        "DRONE_SERVER_HOST" = "ci.thilo-billerbeck.com";
        "DRONE_SERVER_PROTO" = "https";
        "DRONE_USER_CREATE"="username:thilobillerbeck,admin:true";
      };
      volumes = [ "/var/lib/drone:/data" ];
      # ports = [ "4000:80" "4001:443" ];
    };
    "drone-runner" = {
      image = "drone/drone-runner-docker:1";
      environment = {
        "DRONE_RPC_SECRET" = "65e33f4b929df4e4efcb00859e504e8d";
        "DRONE_RPC_HOST" = "ci.thilo-billerbeck.com";
        "DRONE_RPC_PROTO" = "https";
        "DRONE_RUNNER_CAPACITY" = "4";
      };
      volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
      # ports = [ "3000:3000" ];
    };
  };

  users.users.droneserver = {
    isSystemUser = true;
    createHome = true;
    group = droneserver;
  };
  users.groups.droneserver = {};

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
          locations."/".proxyPass = "http://localhost:3001/";
        };
      };
      virtualHosts = {
        "ci.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:4000/";
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
        indexer = {
          REPO_INDEXER_ENABLED = true;
        };
        mailer = {
          ENABLED = true;
          FROM = "\"Thilos Git\" <git@officerent.de>";
          MAILER_TYPE = "smtp";
          HOST = "mail.officerent.de:465";
          IS_TLS_ENABLED = true;
          USER = "git@officerent.de";
        };
      };
    };
    postgresql = {
      enable = true; # Ensure postgresql is enabled
      identMap = # Map the gitea user to postgresql
        ''
          gitea-users gitea gitea

        '';
    };
  };

  programs.mosh = { enable = true; };

  environment.variables.EDITOR = "nvim";

  security.acme = {
    email = "thilo.billerbeck@officerent.de";
    acceptTerms = true;
  };
}

