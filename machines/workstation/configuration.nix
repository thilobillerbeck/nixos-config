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

  nixpkgs.config.packageOverrides = pkgs: {
    mumble = pkgs.mumble.override { pulseSupport = true; };
  };

  networking = {
    hostName = "thilo-pc";
    networkmanager = {
      enable = true;
    };
  };

  system = {
    autoUpgrade.enable = false;
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

      desktopManager.xterm.enable = false;
      displayManager.gdm.enable = true;
      desktopManager.gnome3.enable = true;

      enableCtrlAltBackspace = true;
      videoDrivers = [ "amdgpu" ];

      serverFlagsSection = ''
        Option "AutoAddGPU" "off"
      '';
    };

    journald.extraConfig = "SystemMaxUse=500M";
    autorandr.enable = false;
    timesyncd.enable = true;
    redshift.enable = false;
    printing.enable = true;
    fstrim.enable = true;
    fwupd.enable = true;
    compton = {
      enable = false;
      vSync = true;
    };
  };

  sound.enable = true;

  virtualisation = {
    virtualbox.host = {
      enable = true;
      enableExtensionPack = true;
    };
    docker = {
      enable = true;
      autoPrune.enable = true;
      extraOptions = "--add-runtime runsc=${unstable.gvisor}/bin/runsc --default-runtime=runsc";
    };
    libvirtd = {
      enable = true;
      qemuOvmf = true;
      qemuRunAsRoot = false;
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
  };  

  programs = {
    sway = { enable = true; };
    mosh = { enable = true; };
  };

  environment = {
    variables = {
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
    etc = {
      "i3.conf".text = pkgs.callPackage ./i3-config.nix { };
      "sway/config".text = pkgs.callPackage ./i3-config.nix { };
    };
    systemPackages = with pkgs; [
      virtmanager
    ];
  };

  systemd.tmpfiles.rules = [
    "f /dev/shm/scream 0660 thilo qemu-libvirtd -"
  ];

  systemd.user.services.scream-ivshmem = {
    enable = true;
    description = "Scream IVSHMEM";
    serviceConfig = {
      ExecStart = "${pkgs.scream-receivers}/bin/scream-ivshmem-alsa /dev/shm/scream";
      Restart = "always";
    };
    wantedBy = [ "multi-user.target" ];
    requires = [ "pulseaudio.service" ];
  };
}

