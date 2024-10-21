{ config, pkgs, lib, fetchFromGitea, ... }:

let
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable { config.allowUnfree = true; };
in
{
  imports = [
    ./../../configs/server.nix
    ./hardware.nix
  ];

  environment.systemPackages = with unstable; [ gitea-actions-runner ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.05";

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  networking = {
    hostName = "lisa";
    firewall = { allowedTCPPorts = [ 9002 ]; };
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

  virtualisation = {
    docker = { enable = true; };
  };
}
