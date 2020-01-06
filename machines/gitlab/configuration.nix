{ config, pkgs, ... }:
let 
  gitlab_url = "git.example.com";
  registry_url = "registry.example.com";
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

  networking.firewall.allowedTCPPorts = [ 25 80 443 5000 ];

  services = {
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
      registry = {
        enable = true;
        host = registry_url;
        port =  443;
      };  
      secrets = {
        dbFile = "/var/keys/gitlab/db";
        secretFile = "/var/keys/gitlab/secret";
        otpFile = "/var/keys/gitlab/otp";
        jwsFile = "/var/keys/gitlab/jws";
      };
      extraConfig = {
        gitlab = {
          email_from = "noreply@thilo-billerbeck.com";
          email_display_name = "Thilo's Gitlab";
          email_reply_to = "mail@thilo-billerbeck.com";
          default_projects_features = {
            builds = true;
            container_registry = true;
          };
        };
        packages = { enabled = true; };
      };
    };
  };

  environment.variables.EDITOR = "nvim";
}

