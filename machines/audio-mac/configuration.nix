{ config, pkgs, ... }:

let
  secrets = import ./../../secrets/secrets.nix;
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];

  nixpkgs.config.packageOverrides = pkgs: {
    grub2 = (import <nixpkgs> {system = "i686-linux";}).grub2;
  };

  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.09";
  };

  networking = {
    hostName = "audio-mac";
  };
  networking.firewall.enable = false;

  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;

  nixpkgs.config.allowUnfree = true;

  boot.loader.efi.canTouchEfiVariables = false;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;
  networking.interfaces.wls1.useDHCP = true;

  time.timeZone = "Europe/Berlin";

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
    };
    xrdp.enable = true;
    xrdp.defaultWindowManager = "${pkgs.xfce4-12.xfce4-session}/bin/xfce4-session";
    xserver.desktopManager.xfce.enable = true;
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
    ympd.enable = true;
    mpd = {
    	enable = true;
	    musicDirectory = "${secrets.audio_mac_smb}"; 
    	network.listenAddress = "any";
    };
    shairport-sync.enable = true;
    shairport-sync.arguments = "-a \"Wohnzimmer\" -v -o pa";
    spotifyd = {
      enable = true;
      config = ''
	[global]
backend = alsa
device = front 
mixer = PCM
volume_controller = alsa
device_name = Wohnzimmer
bitrate = 320 
volume_normalisation = true
      '';
    };
  };

  programs.mosh = { enable = true; };

  environment.variables.EDITOR = "nvim";
}

