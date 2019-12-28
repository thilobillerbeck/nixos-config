{ config, pkgs, ... }:
let 
  gitlab_url = "git.thilo-billerbeck.com";
  registry_url = "registry.thilo-billerbeck.com";
  local_registry_port = "5000";
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];

  networking.hostName = "nixos-gitlab"; # Define your hostname.

  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

  time.timeZone = "Europe/Berlin";

  networking.firewall.allowedTCPPorts = [ 25 80 443 4567 ];

  # docker-containers = {
  #   registry = {
  #     image = "registry:2";
  #     ports = [ "5000:5000" ];
  #     environment = {
  #       REGISTRY_AUTH_TOKEN_REALM = "https://git.thilo-billerbeck.com/jwt/auth";
  #       REGISTRY_AUTH_TOKEN_SERVICE = "container_registry";
  #       REGISTRY_AUTH_TOKEN_ISSUER = "gitlab-issuer";
  #     };
  #   };
  # };

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
    };
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
    dockerRegistry = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 5000;
      extraConfig = {
        REGISTRY_AUTH_TOKEN_REALM = "https://${gitlab_url}/jwt/auth";
        REGISTRY_AUTH_TOKEN_SERVICE = "container_registry";
        REGISTRY_AUTH_TOKEN_ISSUER = "gitlab-issuer";
      };
    };
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "${gitlab_url}" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass =
            "http://unix:/run/gitlab/gitlab-workhorse.socket";
        };
        "${registry_url}" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:${local_registry_port}";
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
      host = "${gitlab_url}";
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
          host = "${registry_url}";
          api_url = "http://localhost:${local_registry_port}";
          path = "/var/lib/docker-registry";
          issuer = "gitlab-issuer";
        };
        packages = { enabled = true; };
      };
    };
  };

  programs.mosh = { enable = true; };

  environment.variables.EDITOR = "nvim";
}

