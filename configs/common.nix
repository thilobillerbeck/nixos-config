{ config, pkgs, ... }:

{
  imports = [ ./zsh.nix ./fonts.nix ./packages.nix ./i18n.nix ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    autoOptimiseStore = true;
    gc.automatic = true;
    optimise.automatic = true;
    trustedUsers = [ "root" "thilo" ];
  };
}

