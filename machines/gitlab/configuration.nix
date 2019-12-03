{ config, pkgs, ... }:

{
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];

  networking.hostName = "nixos-gitlab"; # Define your hostname.

  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

  time.timeZone = "Europe/Berlin";

  networking.firewall.allowedTCPPorts = [ 25 80 443 5005 ];

  docker-containers = {
    registry = {
      image = "registry:latest";
      ports = [ "5000:443" ];
      volumes = [
          "/var/lib/acme/registry.thilo-billerbeck.com:/certs"
      ];
      environment = {
	REGISTRY_HTTP_ADDR = "0.0.0.0:443";
        REGISTRY_HTTP_TLS_CERTIFICATE = "/certs/full.pem";
        REGISTRY_HTTP_TLS_KEY = "/certs/key.pem";
      };
    };
  };

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
    };
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
    # dockerRegistry = {
    #	enable = true;
    #	listenAddress = "0.0.0.0";
    #	port = 5000;
    # };
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "git.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass =
            "http://unix:/run/gitlab/gitlab-workhorse.socket";
        };
	"registry.thilo-billerbeck.com" = {
	  enableACME = true;
          forceSSL = true;
	};
      };
    };
    gitlab = {
      enable = true;
      databasePasswordFile = "/var/keys/gitlab/db_password";
      initialRootPasswordFile = "/var/keys/gitlab/root_password";
      databaseUsername = "git";
      backupPath = "/mnt/gitlab-backup";
      https = true;
      host = "git.thilo-billerbeck.com";
      port = 443;
      user = "git";
      group = "git";
      smtp = {
        enable = true;
        address = "localhost";
        port = 25;
      };
      secrets = {
        dbFile = "/var/keys/gitlab/db";
        secretFile = "/var/keys/gitlab/secret";
        otpFile = "/var/keys/gitlab/otp";
        jwsFile = "/var/keys/gitlab/jws";
      };
      extraConfig = {
        gitlab = {
          email_from = "gitlab-no-reply@example.com";
          email_display_name = "Example GitLab";
          email_reply_to = "gitlab-no-reply@example.com";
          default_projects_features = {
	    builds = false;
	    container_registry = true;
	  };
        };
	registry = {
  	  enabled = true;
  	  host = "registry.thilo-billerbeck.com";
  	  port = 5005;
  	  api_url = "https://localhost:5000/";
	};
      };
    };
  };

  programs.mosh = {
    enable = true;
  };

  environment.variables.EDITOR = "nvim";
}

