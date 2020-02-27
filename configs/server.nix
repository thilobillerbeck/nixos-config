{ config, pkgs, ... }:

{
  imports = [ ./zsh.nix ./packages-server.nix ./i18n.nix ];

  nix = {
    autoOptimiseStore = true;
    gc.automatic = true;
    optimise.automatic = true;
    trustedUsers = [ "root" "thilo" ];
  };
}

