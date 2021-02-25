{ config, pkgs, ... }:
let
  gitea_url = "git.thilo-billerbeck.com";
  secrets = import ./../../secrets/secrets.nix;
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
      address = "2a01:4f8:c0c:acf2::1";
      prefixLength = 64;
    } ];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    hostName = "lisa";
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

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
      virtualHosts.${config.services.grafana.domain} = {
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.grafana.port}";
          proxyWebsockets = true;
        };
      };
      virtualHosts."cloud.thilo-billerbeck.com" = {
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.grafana.port}";
          proxyWebsockets = true;
        };
      };
    };
    nextcloud = {
      enable = true;
      hostName = "cloud.thilo-billerbeck.com";
      nginx.enable = true;
      https = true;
      autoUpdateApps.enable = true;
      autoUpdateApps.startAt = "05:00:00";
      config = {
        overwriteProtocol = "https";
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
        dbname = "nextcloud";
        dbpass = secrets.nextcloud.dbpass;
        adminpass = secrets.nextcloud.adminpass;
        adminuser = "admin";
      };
    };
    grafana = {
      enable = true;
      domain = "grafana.thilo-billerbeck.com";
      port = 2342;
      addr = "127.0.0.1";
    };
    prometheus = {
      enable = true;
      port = 9001;
      scrapeConfigs = [
        {
          job_name = "monitoring";
          static_configs = [{
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }];
        }
      ];
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
      };
    };
    postgresql = {
      enable = true;

      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [
        { name = "nextcloud";
          ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
        }
      ];
    };
  }; 
    
  programs.mosh = { enable = true; };

  environment.variables.EDITOR = "nvim";

  systemd.services."nextcloud-setup" = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };

  security.acme = {
    email = "thilo.billerbeck@officerent.de";
    acceptTerms = true;
  };
}

