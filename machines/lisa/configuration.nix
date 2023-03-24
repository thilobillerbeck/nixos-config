{ config, pkgs, lib, ... }:
let
  unstable = import <unstable> { config.allowUnfree = true; };
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/root.nix ./../../users/thilo.nix 
    ./../../modules/woodpecker-agent.nix
    ./../../modules/gitea-runner.nix
    ./../../modules/containers/watchtower.nix
    ./../../modules/colmena-upgrade.nix ];

  environment.systemPackages = with unstable; [ gitea-actions-runner ];


  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.05";

  system.colmenaAutoUpgrade = {
    enable = true;
    nixPath = "nixpkgs=channel:nixos-22.11:unstable=channel:nixos-unstable";
    gitRepoUrl = "https://git.thilo-billerbeck.com/thilobillerbeck/nixos-config.git";
  };

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  
  networking = {
    hostName = "lisa";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    firewall = {
      allowedTCPPorts = [ 5555 ];
    };
  };

  age.secrets = {
    woodpeckerAgentSecret = {
      file = ./../../secrets/woodpecker-secret.age;
      owner = "woodpecker-agent";
      group = "woodpecker-agent";
    };
  };
  
  services = {
    openssh.enable = true;
    woodpecker-agent = {
      enable = true;
      agentSecretFile = config.age.secrets.woodpeckerAgentSecret.path;
      server = "bart.thilo-billerbeck.com:9000";
    };
    gitea-runner = {
      enable = true;
      package = unstable.gitea-actions-runner;
    };
  };

  virtualisation = {
    oci-containers = {
      backend = "docker";
      containers = {
        "dikpostgres" = {
          image = "docker.io/library/postgres:13";
          ports = [ "5555:5432" ];
          volumes = [ "/home/thilo/pg-temp/.pgdata:/var/lib/postgresql/data" ];
          environmentFiles = [ "/var/lib/secrets/dikpostgres.env" ];
        };
      };
    };
    docker = {
      enable = true;
      autoPrune.enable = true;
      daemon.settings = {
        dns = config.networking.nameservers;
      };
    };
  };
}
