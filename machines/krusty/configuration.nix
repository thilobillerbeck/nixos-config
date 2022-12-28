{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/root.nix ./../../users/thilo.nix 
    ./../../modules/colmena-upgrade.nix
    (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master") ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.05";
  
  system.colmenaAutoUpgrade = {
    enable = true;
    nixPath = "nixpkgs=channel:nixos-22.11:unstable=channel:nixos-unstable";
    gitRepoUrl = "https://git.thilo-billerbeck.com/thilobillerbeck/nixos-config.git";
  };

  networking = {
    hostName = "krusty";
    domain = "krusty.thilo-billerbeck.com";
    firewall = {
      allowedTCPPorts = [ 22 80 443 ];
      interfaces = {
        "tailscale0" = {
          allowedUDPPorts = [ 53 3001 3000 ];
          allowedTCPPorts = [ 53 3001 3000 ];
        };
      };
    };
  };

  services = {
    vscode-server.enable = true;
    n8n.enable = true;
    tailscale.enable = true;
    adguardhome = {
      enable = true;
      settings = {
        dns = {
          bind_hosts = [
            "100.72.78.110"
            "fd7a:115c:a1e0:ab12:4843:cd96:6248:4e6e"
          ];
        };
      };
    };
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
