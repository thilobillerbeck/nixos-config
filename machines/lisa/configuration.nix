{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ./../bart/modules/woodpecker-agent.nix
    (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master") ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.05";

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "lisa";
  networking.domain = "lisa.thilo-billerbeck.com";
  services.openssh.enable = true;
  services = {
    vscode-server.enable = true;
    woodpecker-agent = {
      enable = true;
      agentSecretFile = /var/lib/secrets/woodpecker/agentSecret;
      server = "bart.thilo-billerbeck.com:9000";
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
  };
}
