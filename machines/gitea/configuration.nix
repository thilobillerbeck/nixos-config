{ config, pkgs, ... }:
let gitea_url = "git.thilo-billerbeck.com";
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];

  system = {
    autoUpgrade.enable = true;
    autoUpgrade.allowReboot = true;
    stateVersion = "20.03";
  };

  nix.gc.automatic = true;

  networking = {
    hostName = "gitea";
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

  docker-containers."drone" = {
    image = "drone/drone:1";
    environment = {
      "DRONE_GITEA_SERVER" = "https://git.thilo-billerbeck.com";
      "DRONE_GITEA_CLIENT_ID" = "146c9b07-8c10-40c3-8cf4-e391258a6768";
      "DRONE_GITEA_CLIENT_SECRET" =
        "_48BPPhEFm-OJlbJRbXoKM1swcs_PStXJlKOUPPsuiU=";
      "DRONE_RPC_SECRET" = "65e33f4b929df4e4efcb00859e504e8d";
      "DRONE_SERVER_HOST" = "ci.thilo-billerbeck.com";
      "DRONE_SERVER_PROTO" = "https";
    };
    volumes = [ "/var/lib/drone:/data" ];
    ports = [ "4000:80" "4001:443" ];
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
          locations."/".proxyPass = "http://localhost:3000/";
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
      appName = "Thilos SCM";
      rootUrl = "https://git.thilo-billerbeck.com/";
      log.level = "Warn";
      database = {
        type = "postgres";
        password = "gitea";
      };
      extraConfig = ''
        	        APP_NAME = Thilos SCM

        	        [service]
                 	DISABLE_REGISTRATION = true

        	        [ui]
                  	DEFAULT_THEME = arc-green
        	        SHOW_USER_EMAIL = false

			[indexer]
			REPO_INDEXER_ENABLED = true;

			[mailer]
                    	ENABLED        = true
                    	FROM           = git@officerent.de
                    	MAILER_TYPE    = smtp
                    	HOST           = mail.officerent.de:587
                   	IS_TLS_ENABLED = true
                    	USER           = git@officerent.de
                    	PASSWD         = `cogypost91`
        	      '';
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

