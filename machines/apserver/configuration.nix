{ config, pkgs, ... }:

{
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];

  networking.hostName = "nixos-appserver";

  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

  time.timeZone = "Europe/Berlin";

  networking.firewall.allowedTCPPorts = [ 80 443 3000 996 7946 4789 2377 ];
  networking.firewall.allowedUDPPorts = [ 7946 4789 2377 ];

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
    };
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
  };
  
  programs.mosh = {
    enable = true;
  };
  
  virtualisation.docker = {
    enable = true;
    liveRestore = false;
  };

  environment.variables.EDITOR = "nvim";
}

