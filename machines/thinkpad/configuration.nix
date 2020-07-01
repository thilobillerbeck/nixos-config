{ config, pkgs, ... }:

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports = [
    ./../../configs/common.nix
    ./hardware.nix
    ./../../users/thilo.nix
    ./../../home/default.nix
  ];

  networking.hostName = "thilo-laptop";
  networking.networkmanager.enable = true;
  
  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

  time.timeZone = "Europe/Berlin";

  services = {
    tlp.enable = true;
    fwupd.enable = true;
    openssh = {
      enable = true;
      passwordAuthentication = true;
      challengeResponseAuthentication = false;
    };

    dbus.packages = with pkgs; [ gnome3.dconf ];
    xserver = {
      enable = true;
      layout = "de";

      libinput.enable = true;

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
        Option  "Backlight"  "amdgpu_bl0"
      '';

    };
    journald.extraConfig = "SystemMaxUse=500M";
    printing.enable = true;
    timesyncd.enable = true;
    blueman.enable = true;
    compton = {
      enable = true;
      vSync = true;
    };
  };

  programs.sway = { enable = true; };
  programs.mosh = { enable = true; };

  environment = {
    etc."i3.conf".text = pkgs.callPackage ./i3-config.nix { };
    variables = {
      TERM = "xterm-256color";
      EDITOR = "nvim";
      LC_ALL = config.i18n.defaultLocale;
    };
    shellAliases = {
      cccda-weechat =
        ''ssh -t avocadoom@shells.darmstadt.ccc.de "tmux attach -t weechat"'';
      w17-door-summer = "ssh summer@door.w17.io";
      w17-door-open = "ssh open@door.w17.io";
      w17-door-close = "ssh close@door.w17.io";
      wine = "wine64";
    };
  };

  sound.enable = true;
  hardware.bluetooth.enable = true;

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
      extraOptions = "--add-runtime runsc=${unstable.gvisor}/bin/runsc";
    };

    libvirtd = {
      enable = true;
      qemuOvmf = true;
      qemuRunAsRoot = true;
    };
  };


  programs.adb.enable = true;
  services.udev.packages = [
    pkgs.android-udev-rules
  ];
}

