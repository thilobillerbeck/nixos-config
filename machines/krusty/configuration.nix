{ config, pkgs, lib, ... }:
let
  unstable = import <unstable> { config.allowUnfree = true; };
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/root.nix ./../../users/thilo.nix 
    ./../../modules/colmena-upgrade.nix
    ./../../modules/containers/watchtower.nix
     ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.05";
  
  system.colmenaAutoUpgrade = {
    enable = true;
    nixPath = "nixpkgs=channel:nixos-22.11:unstable=channel:nixos-unstable";
    gitRepoUrl = "https://git.thilo-billerbeck.com/thilobillerbeck/nixos-config.git";
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
      };
    };
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
  };


  networking = {
    hostName = "krusty";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    firewall = {
      allowedTCPPorts = [ 22 80 443 ];
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
    };
  };
};
}