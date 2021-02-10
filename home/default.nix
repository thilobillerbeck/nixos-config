{ config, lib, pkgs, ... }:

with lib;
with import <nixpkgs> { };

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
#    rev = "6dc8de259a36313ebd1ee25b075174e396f53329";
    ref = "release-20.09";
  };
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports = [ "${home-manager}/nixos" ];

  home-manager.useGlobalPkgs = true;
  home-manager.verbose = true;
  home-manager.users.thilo = { ... }: {
    imports = [
      # ./services/polybar.nix
      ./programs/rofi.nix
      ./programs/git.nix
      ./programs/neovim.nix
      ./programs/termite.nix
    ];

    services.network-manager-applet.enable = if (config.networking.hostName == "thilo-pc") then false else true;
    services.blueman-applet.enable =  if (config.networking.hostName == "thilo-pc") then false else true;
    services.pasystray.enable = if (config.networking.hostName == "thilo-pc") then false else true;
    services.lorri.enable = true;

    programs = {
      bat = { enable = true; };
      chromium = { enable = true; };
      fzf = { enable = true; };
      direnv = { enable = true; };
      go = {
        enable = true;
        package = unstable.go;
      };
      htop = { enable = true; };
      jq = { enable = true; };
      mpv = { enable = true; };
      obs-studio = { enable = true; };
      tmux = { enable = true; };
      vscode = {
        enable = true;
        package = unstable.vscode;
      };
    };

    qt = {
      enable = true;
      platformTheme = "gtk";
    };

    gtk = {
      enable = true;
      theme = {
        package = pkgs.pop-gtk-theme;
        name = "Pop";
      };
      iconTheme = {
        package = pkgs.pop-icon-theme;
        name = "Pop";
      };
      gtk3 = { extraConfig = {
        gtk-application-prefer-dark-theme = true;
#        gtk-modules = "appmenu-gtk-module";
        };
      };
    };
  };
}
