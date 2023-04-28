{ config, pkgs, lib, fetchFromGitea, ... }:

let
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable { config.allowUnfree = true; };
in {
  imports = [ ./../../configs/server.nix ./hardware.nix ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.11";

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  networking = {
    hostName = "skinner";
    firewall = { allowedTCPPorts = [ 80 443 ]; };
  };

  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "skinner.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:9000";
        };
        "wiki.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:6875";
        };
      };
    };
  };

  virtualisation = {
    docker = { enable = true; };
    oci-containers = {
      backend = "docker";
      containers = {
        "portainer" = {
          ports = [ "8000:8000" "9000:9000" "9443:9443" ];
          image = "portainer/portainer-ce:latest";
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "/var/lib/portainer:/data"
          ];
        };
        "watchtower" = {
          image = "containrrr/watchtower:latest";
          volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
        };
      };
    };
  };
}
