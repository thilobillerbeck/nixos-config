{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/root.nix ./../../users/thilo.nix 
    ./../../modules/woodpecker-agent.nix
    ./../../modules/colmena-upgrade.nix
    (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master") ];

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
    domain = "lisa.thilo-billerbeck.com";
    nameservers = [ "1.1.1.1" "1.0.0.1"  ];
    firewall = {
      allowedTCPPorts = [ 5555 ];
    };
  };
  
  services = {
    openssh.enable = true;
    vscode-server.enable = true;
    woodpecker-agent = {
      enable = true;
      agentSecretFile = "/var/lib/secrets/woodpecker/agentSecret";
      server = "bart.thilo-billerbeck.com:9000";
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
    };
  };
}
