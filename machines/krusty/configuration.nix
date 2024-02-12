{ config, pkgs, lib, ... }:
let
  invoiceninja_app = "invoiceninja";
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable { config.allowUnfree = true; };
in
{
  imports = [
    ./../../configs/server.nix
    ./hardware.nix
    ./../../modules/containers/watchtower.nix
    ./../../users/deploy.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.05";

  virtualisation = {
    oci-containers = {
      backend = "docker";
      containers = {
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
    firewall = { allowedTCPPorts = [ 22 80 443 9001 8055 9002 ]; };
  };

  systemd.services.trilium-server.serviceConfig.ExecStart = lib.mkForce "${unstable.trilium-server}/bin/trilium-server";

  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
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
    prometheus = {
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
      };
    };
  };
}
