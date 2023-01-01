{ config, pkgs, ... }:
let 
  unstable = import <unstable> { config.allowUnfree = true; };
in {
  imports = [ ./zsh.nix ./packages-server.nix ./i18n.nix "${builtins.fetchTarball "https://github.com/ryantm/agenix/archive/main.tar.gz"}/modules/age.nix" ];

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

  networking.firewall = {
    allowedTCPPorts = [ 19999 ];
    allowedUDPPorts = [ 19999 ];
  };

  programs.mosh = { enable = true; };

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "yes";
    };
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
    netdata = {
      enable = true;
      package = unstable.netdata;
    };
  };

  environment.variables.EDITOR = "nvim";

  security.acme = {
    defaults.email = "thilo.billerbeck@officerent.de";
    acceptTerms = true;
  };

  system = {
    autoUpgrade = {
      enable = false;
      allowReboot = true;
      flags = [ "--upgrade-all" ];
      rebootWindow = {
        lower = "05:00";
        upper = "06:00";
      };
    };
  };

  nixpkgs.config.allowUnfree = true;
}

