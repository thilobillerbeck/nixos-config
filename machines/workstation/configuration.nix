{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports =
    [ ./../../configs/common.nix ./hardware.nix  ./../../home/default.nix ./../../users/thilo.nix ];

  networking.hostName = "thilo-pc";
  networking.networkmanager.enable = true;

  nixpkgs.config.packageOverrides = pkgs: { libvirt = pkgs.libvirt.override { enableIscsi = true; }; };

  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

  location = {
    latitude = 49.8217934;
    longitude = 8.9421667;
  };

  time.timeZone = "Europe/Berlin";

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = true;
      challengeResponseAuthentication = false;
    };

    fwupd = {
      enable = true;
      package = unstable.fwupd;
    };

    xserver = {
      enable = true;
      layout = "de";

      desktopManager.xterm.enable = false;
      displayManager.lightdm.enable = true;

      windowManager.i3 = {
        enable = true;
        configFile = "/etc/i3.conf";
        package = pkgs.i3-gaps;
        extraPackages = with pkgs; [
          i3status # gives you the default i3 status bar
          i3lock-fancy # default i3 screen locker
          i3blocks # if you are planning on using i3blocks over i3status
          polybar
          xorg.xbacklight
        ];
      };

      enableCtrlAltBackspace = true;
      videoDrivers = [ "amdgpu" ];

      serverFlagsSection = ''
        Option "AutoAddGPU" "off"
      '';
    };

    journald.extraConfig = "SystemMaxUse=500M";
    printing.enable = true;
    timesyncd.enable = true;
    redshift.enable = true;
  };

  sound.enable = true;

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
    libvirtd = {
      enable = true;
      qemuOvmf = true;
      qemuRunAsRoot = true;
      extraConfig = ''
        unix_sock_rw_perms = "0777"
      '';
      qemuVerbatimConfig = ''
        namespaces = []
        dynamic_ownership = 0
        security_driver = "none"
        user = "root"
        group = "root"
        '';
    };
  };

  programs.sway = {
    enable = true;
  };
  programs.mosh = {
    enable = true;
  };
  programs.adb.enable = true;

  environment.variables.EDITOR = "nvim";
  environment.etc."i3.conf".text = pkgs.callPackage ./i3-config.nix { };
  environment.etc."sway/config".text = pkgs.callPackage ./i3-config.nix { };
  environment.systemPackages = with pkgs; [ virtmanager pulseaudioFull ];
}

