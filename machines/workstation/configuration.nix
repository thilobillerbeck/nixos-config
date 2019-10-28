{ config, pkgs, ... }:

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports =
    [ ./../../configs/common.nix ./hardware.nix ./../../users/thilo.nix ];

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

  time.timeZone = "Europe/Berlin";

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = true;
      challengeResponseAuthentication = false;
    };

    xserver = {
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
    };
  };

  environment.variables.EDITOR = "nvim";
  environment.systemPackages = with pkgs; [ virtmanager pulseaudioFull ];
}

