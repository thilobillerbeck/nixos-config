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
      containers = {
        "digitaltwinapp-postgres" = {
          image = "docker.io/library/postgres:13";
          ports = [ "5555:5432" ];
          volumes = [ "/home/thilo/pg-temp/.pgdata:/var/lib/postgresql/data" ];
          environmentFiles = [ "/var/lib/secrets/dikpostgres.env" ];
        };
      };
    };
    docker = { enable = true; };
  };
}
