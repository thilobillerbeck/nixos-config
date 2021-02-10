{ config, pkgs, ... }:

{
  imports = [ ./zsh.nix ./packages-server.nix ./i18n.nix ];

  nix = {
    autoOptimiseStore = true;
    gc.automatic = true;
    gc.options = "--delete-older-than 3d";
    optimise.automatic = true;
    trustedUsers = [ "root" "thilo" ];
  };

  programs.mosh = { enable = true; };

  environment.variables.EDITOR = "nvim";

  security.acme = {
    email = "thilo.billerbeck@officerent.de";
    acceptTerms = true;
  };
}

