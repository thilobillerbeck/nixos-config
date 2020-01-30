{ config, pkgs, fetchFromGitHub, ... }:

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports = [
    ./../../configs/common.nix
    ./../../configs/cachix.nix
    ./hardware.nix
    ./../../home/default.nix
    ./../../users/thilo.nix
    ./../../users/root.nix
  ];

  networking = {
    hostName = "thilo-pc";
    networkmanager = {
      enable = true;
    };
    firewall = {
      allowedTCPPorts = [ 27036 27037 6112 47624 ];
      allowedUDPPorts = [ 27031 27036 6112 34197 ];
      allowedUDPPortRanges = [
        { from = 2300; to = 2400; }
      ];
      allowedTCPPortRanges = [
        { from = 2300; to = 2400; }
      ];
    };
  };



  system = {
    autoUpgrade.enable = false;
    stateVersion = "19.03";
  };

  nix.trustedUsers = [ "root" "thilo" ];

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
      desktopManager.gnome3.enable = true;
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
    timesyncd.enable = true;
    redshift.enable = true;
    compton = {
      enable = true;
      vSync = true;
    };
    printing = {
      enable = true;
    };
    autorandr.enable = true;
  };

  sound.enable = true;

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
      extraOptions = "--add-runtime runsc=${unstable.gvisor}/bin/runsc --default-runtime=runsc";
    };
    libvirtd = {
      enable = true;
      qemuOvmf = true;
      qemuRunAsRoot = true;
    };
  };

  programs.sway = { enable = true; };
  programs.mosh = { enable = true; };
  programs.adb.enable = true;

  environment.variables.EDITOR = "nvim";
  environment.etc."i3.conf".text = pkgs.callPackage ./i3-config.nix { };
  environment.etc."sway/config".text = pkgs.callPackage ./i3-config.nix { };
  environment.systemPackages = with pkgs; [ virtmanager pulseaudioFull ];
}

