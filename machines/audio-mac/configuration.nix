{ config, pkgs, ... }:
let 
  gitlab_url = "git.thilo-billerbeck.com";
  registry_url = "registry.thilo-billerbeck.com";
  local_registry_port = "5000";
in {
  imports =
    [ ./../../configs/server.nix ./hardware.nix ./../../users/thilo.nix ];

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
    xrdp.defaultWindowManager = "${pkgs.icewm}/bin/icewm";
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
    ympd.enable = true;
    mpd = {
    	enable = true;
	musicDirectory = "smb://thilo:thilo22061998@192.168.50.240/music"; 
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

