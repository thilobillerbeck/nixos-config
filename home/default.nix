{ config, lib, ... }:
let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "b0544c8cded820fc1439c26b4fc7485846430516";
    ref = "master";
  };
in {
  imports = [ "${home-manager}/nixos" ];

  home-manager.users.thilo = { ... }: {
    services.network-manager-applet.enable = true;
    services.blueman-applet.enable = true;
    services.network-manager-applet.enable = true;

    programs.git = {
      enable = true;
      userName = "Thilo Billerbeck";
      userEmail = "thilo.billerbeck@officerent.de";
    };
  };
}
