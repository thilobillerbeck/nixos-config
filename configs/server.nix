{ config, pkgs, ... }:

{
  imports = [ ./zsh.nix ./packages-server.nix ./i18n.nix ];

  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 3d";
      dates = "daily";
    };
    optimise.automatic = true;
    trustedUsers = [ "root" "thilo" ];
  };

  programs.mosh = { enable = true; };

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "no";
    };
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
  };

  environment.variables.EDITOR = "nvim";

  security.acme = {
    defaults.email = "thilo.billerbeck@officerent.de";
    acceptTerms = true;
  };

  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = true;
      flags = [
        "--upgrade-all"
      ];
      rebootWindow = {
        lower = "05:00";
        upper = "06:00";
      };
    };
  };

  nixpkgs.config.allowUnfree = true;
}

