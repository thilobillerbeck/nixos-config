{ config, pkgs, lib, fetchFromGitea, ... }:

let
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable { config.allowUnfree = true; };
in
{
  imports = [
    ./../../configs/server.nix
    ./hardware.nix
    ./../../modules/colmena-upgrade.nix
  ];

  environment.systemPackages = with unstable; [ gitea-actions-runner ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.05";

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  networking = {
    hostName = "lisa";
    firewall = { allowedTCPPorts = [ 5555 9002 ]; };
  };

  services = {
    gitea-actions-runner = {
      package = unstable.gitea-actions-runner;
      instances = {
        lisa_docker = {
          name = "lisa_docker";
          enable = true;
          labels = [
            "docker:docker://node:16-bullseye"
          ];
          url = "https://git.thilo-billerbeck.com";
          token = "replace-me";
        };
      };
    };
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
