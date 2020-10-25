{ config, pkgs, ... }:
let 
  gitea_url = "git2.thilo-billerbeck.com";
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];

  system = {
    autoUpgrade.enable = true;
    stateVersion = "20.03";
  };

  networking = {
    hostName = "gitea";
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

  time.timeZone = "Europe/Berlin";

  services = {
    openssh = {
      enable = true;
    };
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
          locations."/".proxyPass =
            "http://localhost:3000/";
        };
      };
    };
    gitea = {
        enable = true;
        cookieSecure = true;
        appName = "Thilos SCM";
        rootUrl = "https://git2.thilo-billerbeck.com/";
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
	      '';
    };
    postgresql = {
      enable = true;                # Ensure postgresql is enabled
      identMap =                    # Map the gitea user to postgresql
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

