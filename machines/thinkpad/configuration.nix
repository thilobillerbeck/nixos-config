{ config, pkgs, ... }:

imports = [ ./../../configs/common.nix ./hardware.nix ];                                    

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  networking.hostName = "thilo-laptop";
  networking.networkmanager.enable = true;

  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  environment.systemPackages = with pkgs;
    [
      # lemonbar
    ];

  time.timeZone = "Europe/Berlin";

  environment.etc."xdg/gtk-3.0/settings.ini" = {
    text = ''
      [Settings]
      gtk-icon-theme-name=Numix-circle
      gtk-theme-name=Numix
      gtk-application-prefer-dark-theme = true
    '';
  };

  environment.etc."config/polybar" = {
    text = ''
      [bar/example]
      width = 100%
      height = 27
      radius = 6.0
      fixed-center = false 
    '';
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
  };

  services.xserver = {
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

  services.journald.extraConfig = "SystemMaxUse=500M";
  services.printing.enable = true;
  services.timesyncd.enable = true;

  users.users.thilo = {
    uid = 1000;
    description = "Thilo Billerbeck <thilo.billerbeck@officerent.de>";
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    pulseaudio = {
      enable = true;
      support32Bit = true;
    };
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  };

  environment.variables.EDITOR = "termite";
  environment.etc."i3.conf".text = pkgs.callPackage ./i3-config.nix { };

  sound.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
  };
  security.sudo.wheelNeedsPassword = false;
}

