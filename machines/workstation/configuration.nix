{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config.allowUnfree = true;
  };
in {
  networking.hostName = "thilo-pc"; 

  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

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
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
  };

  services.xserver = {
    enable = true;
    layout = "de";

    displayManager.gdm.enable = true;
    desktopManager.gnome3.enable = true;
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
    extraGroups = [ "wheel"  "docker"  "libvirtd"  "qemu-libvirtd" ]; 
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

  environment.systemPackages = with pkgs; [
    virtmanager
  ];
}

