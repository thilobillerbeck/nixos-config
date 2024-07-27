{ config, pkgs, lib, ... }:

let
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable {
    config.allowUnfree = true;
    system = "aarch64-linux";
  };
  prometheus_hosts = [
    "bart"
    "burns"
    "krusty"
    "lisa"
    "marge"
    "skinner"
  ];
in
{
  imports = [
    ./hardware.nix
    ./../../configs/server.nix
    ./../../users/deploy.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "23.11";

  networking = {
    hostName = "skinner";
    firewall = { allowedTCPPorts = [ 22 80 443 5001 8080 9001 51820 51821  ]; };
    networkmanager.enable = true;
  };

  virtualisation = {
    oci-containers = {
      backend = "docker";
      containers = {
        "n8n" = {
          ports = [ "5678:5678" ];
          user = "root";
          image = "docker.n8n.io/n8nio/n8n";
          volumes = [ "/var/lib/n8n:/home/node/.n8n" ];
        };
      };
    };
    docker = {
      enable = true;
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
          locations."/" = {
            proxyWebsockets = true;
            proxyPass = "http://localhost:5678";
          };
        };
        "testcloud.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyWebsockets = true;
            proxyPass = "http://localhost:11000";
          };
        };
      };
    };
    gitea-actions-runner = {
      package = pkgs.forgejo-actions-runner;
      instances.skinner-secretary = {
        settings = {
          container = {
            network = "host";
          };
        };
        enable = true;
        name = config.networking.hostName;
        token = "";
        url = "https://git.thilo-billerbeck.com";
        labels = [
          "native:host"
          "debian-latest:docker://node:18-bullseye"
          "ubuntu-latest:docker://node:18-bullseye"
        ];
      };
    };
    prometheus = {
      enable = true;
      port = 9001;
      scrapeConfigs = lib.imap0 (i: v: {
        job_name = v;
        static_configs = [{
            targets = [ "${v}.thilo-billerbeck.com:9002" ];
        }];
      }) prometheus_hosts;
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
