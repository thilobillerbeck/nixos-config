{ config, pkgs, lib, fetchFromGitea, ... }:

let
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable { config.allowUnfree = true; };
in {
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
    firewall = { allowedTCPPorts = [ 5555 ]; };
  };

  services = {
    netdata = {
      enable = true;
      package = unstable.netdata;
    };
  };

  virtualisation = {
    oci-containers = {
      backend = "podman";
    };
    docker = { enable = true; };
  };
}
