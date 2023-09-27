{ config, pkgs, lib, ... }:

let
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable {
    config.allowUnfree = true;
    system = "aarch64-linux";
  };
in
{
  imports = [
    ./hardware.nix
    ./../../configs/server.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "23.11";


  networking = {
    hostName = "skinner";
    firewall = { allowedTCPPorts = [ 22 80 443 ]; };
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
    docker = { enable = true; };
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
      };
    };
  };
}
