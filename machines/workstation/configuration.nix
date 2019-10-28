{ config, pkgs, ... }:

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports = [ ./../../configs/common.nix ./hardware.nix ];

  networking.hostName = "thilo-pc";
  networking.networkmanager.enable = true;

  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

  location = {
    latitude = 49.8217934;
    longitude = 8.9421667;
  };

  # boot.extraModprobeConfig = "options vfio-pci ids=1002:687f,1002:aaf8,1022:145c";
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  time.timeZone = "Europe/Berlin";

  environment.etc."xdg/gtk-3.0/settings.ini" = {
    text = ''
      [Settings]
      gtk-icon-theme-name=Numix-circle
      gtk-theme-name=Numix
      gtk-application-prefer-dark-theme = true
    '';
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = true;
    challengeResponseAuthentication = false;
  };

  services.xserver = {
    enable = true;
    layout = "de";

    displayManager.lightdm.enable = true;
    desktopManager.xfce4-14.enable = true;
    enableCtrlAltBackspace = true;
    videoDrivers = [ "amdgpu" ];

    serverFlagsSection = ''
      Option "AutoAddGPU" "off"
    '';
  };

  services.journald.extraConfig = "SystemMaxUse=500M";
  services.printing.enable = true;
  services.timesyncd.enable = true;
  services.redshift.enable = true;

  hardware = {
    cpu.amd.updateMicrocode = true;
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    steam-hardware.enable = true;
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

  sound.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
    libvirtd = {
      enable = true;
      qemuOvmf = true;
    };
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [ virtmanager pulseaudioFull ];
}

