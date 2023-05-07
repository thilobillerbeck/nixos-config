{ config, pkgs, lib, ... }:
let unstable = import <unstable> { config.allowUnfree = true; };
in {
  imports = [
    ./../../configs/server.nix
    ./hardware.nix
    ./../../modules/colmena-upgrade.nix
    ./../../modules/containers/watchtower.nix
    ./../../users/deploy.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.05";

  system.colmenaAutoUpgrade = {
    enable = true;
    nixPath = "nixpkgs=channel:nixos-22.11:unstable=channel:nixos-unstable";
    gitRepoUrl =
      "https://git.thilo-billerbeck.com/thilobillerbeck/nixos-config.git";
  };

  virtualisation = {
    oci-containers = {
      backend = "docker";
      containers = {
        "n8n" = {
          ports = [ "5678:5678" ];
          image = "n8nio/n8n:latest";
          volumes = [ "/var/lib/n8n:/home/node/.n8n" ];
        };
        "portainer_agent" = {
          image = "portainer/agent:latest";
          ports = [ "9001:9001" ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "/var/lib/docker/volumes:/var/lib/docker/volumes"
            ];
        };
      };
    };
    docker = { enable = true; };
  };

  networking = {
    hostName = "krusty";
    firewall = { allowedTCPPorts = [ 22 80 443 9001 ]; };
  };

  systemd.services.invoicePocketbase = {
      wantedBy = [ "multi-user.target" ]; 
      after = [ "network.target" ];
      description = "pocketbase";
      serviceConfig = {
        Type = "simple";
        User = "root";
        Group = "root";
        LimitNOFILE = "4096";
        Restart        = "always";
        RestartSec     = "5s";
        ExecStart = ''${unstable.pocketbase}/bin/pocketbase serve --http localhost:3456 --dir /var/lib/pb/invoiceapi/data --publicDir /var/lib/pb/invoiceapi/public'';
      };
   };

  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "n8n.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:5678";
        };
        "invoiceapi.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:3456";
        };
      };
    };
    netdata = {
      enable = true;
      package = unstable.netdata;
    };
  };
}
