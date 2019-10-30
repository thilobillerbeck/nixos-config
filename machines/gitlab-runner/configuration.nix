{ config, pkgs, ... }:

{
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];

  networking.hostName = "gitlab-runner-1"; # Define your hostname.

  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

  time.timeZone = "Europe/Berlin";

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
    }; 
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
    gitlab-runner = {
      enable = true;
      configOptions = {
        concurrent = 1;
        runners = [{
          name = "gitlab-runner-1";
          url = "https://git.thilo-billerbeck.com/";
          token = "2zWyrsJ3zDD4z1bXsZWv";
          executor = "docker";
          builds_dir = "";
          docker = {
            host = "";
            image = "alpine";
            privileged = true;
            disable_cache = true;
            cache_dir = "";
          };
        }];
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
  };

  environment.variables.EDITOR = "nvim";
}

