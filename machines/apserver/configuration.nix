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

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
    };
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."thilo-billerbeck.com" = {
        addSSL = true;
        enableACME = true;
        root = "/var/www/thilo-billerbeck.com";
      };
    };
  };

  environment.variables.EDITOR = "nvim";
}

