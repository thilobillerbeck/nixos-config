{ config, pkgs, lib,  ... }:
let
  sources = import ./../../nix/sources.nix;
  unstable =  import sources.unstable { config.allowUnfree = true; };
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

  virtualisation = {
    oci-containers = {
      backend = "docker";
      containers = {
        "n8n" = {
          ports = [ "5678:5678" ];
          image = "n8nio/n8n:latest";
          volumes = [ "/var/lib/n8n:/home/node/.n8n" ];
        };
        "directus" = {
          ports = [ "8055:8055" ];
          image = "directus/directus:latest";
          volumes = [
              "directus-database:/directus/database"
              "directus-uploads:/directus/uploads"
           ];
          environmentFiles = [
            /var/lib/directus/.env
          ];
        };
        "kimai-db" = {
          image = "mysql";
          volumes = [ "kimai-database:/var/lib/mysql" ];
          environmentFiles = [
            /var/lib/kimai/.env-db
          ];
          extraOptions = [
            "--network=kimai"
          ];
        };
        "kimai" = {
          ports = [ "8056:8001" ];
          image = "kimai/kimai2:apache";
          environmentFiles = [
            /var/lib/kimai/.env
          ];
          extraOptions = [
            "--network=kimai"
          ];
        };
      };
    };
    docker = { enable = true; };
  };

  networking = {
    hostName = "krusty";
    firewall = { allowedTCPPorts = [ 22 80 443 9001 8055 ]; };
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
        "directus.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:8055";
        };
        "kimai.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:8056";
        };
        "trilium.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.trilium-server.port}/";
            proxyWebsockets = true;
          };
        };
      };
    };
    trilium-server.enable = true;
  };
}
