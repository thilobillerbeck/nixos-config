{ config, pkgs, ... }:

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports =
  [ ./../../configs/common.nix ./hardware.nix ./../../users/thilo.nix ];

  networking.hostName = "thilo-laptop";
  networking.networkmanager.enable = true;

  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

  time.timeZone = "Europe/Berlin";

  environment.etc."config/polybar" = {
    text = ''
      [bar/example]
      width = 100%
      height = 27
      radius = 6.0
      fixed-center = false 
    '';
  };

  services = {
    xserver = {
      enable = true;
      layout = "de";

      libinput.enable = true;

      desktopManager.xterm.enable = false;
      displayManager.lightdm.enable = true;

      windowManager.i3 = {
        enable = true;
        configFile = "/etc/i3.conf";
        extraPackages = with pkgs; [
          i3status # gives you the default i3 status bar
          i3lock # default i3 screen locker
          i3blocks # if you are planning on using i3blocks over i3status
          polybar
          rofi
        ];
      };

      enableCtrlAltBackspace = true;
      videoDrivers = [ "amdgpu" ];
    };
    journald.extraConfig = "SystemMaxUse=500M";
    printing.enable = true;
    timesyncd.enable = true;
  };

  environment.variables.TERM = "xterm-256color";
  environment.variables.EDITOR = "nvim";
  environment.etc."i3.conf".text = pkgs.callPackage ./i3-config.nix { };

  sound.enable = true;

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
  };
}

