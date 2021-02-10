{ config, pkgs, ... }:
let 
  gitlab_url = "git.thilo-billerbeck.com";
  registry_url = "registry.thilo-billerbeck.com";
  local_registry_port = "5000";
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];


  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

  networking = {
    hostName = "nixos-gitlab";
    firewall.allowedTCPPorts = [ 25 80 443 3000 ];
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
    dockerRegistry = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 5000;
      enableDelete = true;
      extraConfig = {
        REGISTRY_LOG_LEVEL = "info";
        REGISTRY_AUTH_TOKEN_REALM = "https://git.thilo-billerbeck.com/jwt/auth";
        REGISTRY_AUTH_TOKEN_SERVICE = "container_registry";
        REGISTRY_AUTH_TOKEN_ISSUER = "gitlab-issuer";
        REGISTRY_AUTH_TOKEN_ROOTCERTBUNDLE = "/certs/registry.crt";
        REGISTRY_STORAGE_DELETE_ENABLED = "true";
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
          locations."/".proxyPass = "http://127.0.0.1:5000";
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
            builds = true;
            container_registry = true;
          };
        };
        registry = {
          enabled = true;
          host = "${registry_url}";
          port = 443;
          key = "/certs/registry.key";
          api_url = "http://localhost:5000/";
          issuer = "gitlab-issuer";
        };
        packages = { enabled = true; };
      };
    };
  };

  programs.mosh = { enable = true; };

  environment.variables.EDITOR = "nvim";
}

