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
    firewall.allowedTCPPorts = [ 80 443 ];
  };

  time.timeZone = "Europe/Berlin";

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
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
        domain = "git2.thilo-billerbeck.com";
        rootUrl = "https://git2.thilo-billerbeck.com/";
        database = {
          type = "postgres";                        # Database type
          password = "gitea";                       # Set the password
        };
        extraConfig = ''
	  [service]
          DISABLE_REGISTRATION = true

	  [ui]
          DEFAULT_THEME = arc-green
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

  users.users.gitea = {
    description = "Gitea Service";
    isNormalUser = true;
    home = config.services.gitea.stateDir;
    createHome = true;
    useDefaultShell = true;
  };

  security.acme = {
    email = "thilo.billerbeck@officerent.de";
    acceptTerms = true;
  };
}

