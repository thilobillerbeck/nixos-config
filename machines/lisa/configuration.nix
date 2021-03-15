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
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.grafana.port}";
          proxyWebsockets = true;
        };
      };
      virtualHosts."zabbix.thilo-billerbeck.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;
        };
      };
    };
    zabbixServer = {
      enable = true;
      openFirewall = true;
    };
    zabbixWeb = {
     virtualHost = {
       # hostName = "zabbix.thilo-billerbeck.com";
       adminAddr = "webmaster@localhost";
       listen = [
           {
    ip = "*";
    port = 8080;
  }
       ];
     }; 
     enable = true;
    };
    zabbixAgent = {
      enable = true;
      server = "localhost";
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
  }; 
    
  programs.mosh = { enable = true; };

  environment.variables.EDITOR = "nvim";

  security.acme = {
    email = "thilo.billerbeck@officerent.de";
    acceptTerms = true;
  };
}

