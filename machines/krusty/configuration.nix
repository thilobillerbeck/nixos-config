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
    ./../../users/deploy.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.05";

  virtualisation = {
    docker = { enable = true; };
  };

  networking = {
    hostName = "krusty";
    firewall = { allowedTCPPorts = [ 22 80 443 ]; };
  };

  services = {
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
