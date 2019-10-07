{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config.allowUnfree = true;
  };
in {
  nixpkgs.config.allowUnfree = true;
  system.autoUpgrade.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thilo-laptop"; 

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "de";
    defaultLocale = "en_US.UTF-8";
  };

  services.timesyncd.enable = true;

  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    ddate
    file
    htop
    manpages
    tmux
    tree
    wget
    vim
    neovim
    zsh
    chromium
    vscode
    git
    gnumake
    gcc
    linuxHeaders
    spotify
    numix-gtk-theme
    numix-icon-theme-circle
    gnupg
    curl
    unzip
    imagemagick
    youtube-dl
    unstable.go
    openjdk
    nodejs
    watchman
    vagrant
    kubectl
    steam
    python3
    discord

    unstable.jetbrains.goland
    unstable.jetbrains.idea-ultimate
    unstable.jetbrains.phpstorm
    unstable.jetbrains.pycharm-professional
    unstable.jetbrains.webstorm
  ];

  environment.etc."xdg/gtk-3.0/settings.ini" = {
    text = ''
      [Settings]
      gtk-icon-theme-name=Numix-circle
      gtk-theme-name=Numix
      gtk-application-prefer-dark-theme = true
    '';
  };

  programs.zsh =  {
    enable = true;
    ohMyZsh = {
      enable = true;
    };
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
  };

  services.printing.enable = true;
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.xserver.enable = true;
  services.xserver.layout = "de";
  # services.xserver.xkbOptions = "eurosign:e";

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome3.enable = true;
  services.xserver.enableCtrlAltBackspace = true;

  users.users.thilo = {
    uid = 1000;
    description = "Thilo Billerbeck <thilo.billerbeck@officerent.de>";
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel"  "docker" ]; 
  };

  system.stateVersion = "19.03";

  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.cpu.amd.updateMicrocode = true;                                                                  
  boot.kernelPackages = pkgs.linuxPackages_testing;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true; 

  security.sudo.wheelNeedsPassword = false;

  services.journald.extraConfig = "SystemMaxUse=500M";

  nix.gc.automatic = true;
  nix.optimise.automatic = true;

  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fontconfig.cache32Bit = true;
    fontconfig.ultimate.preset = "osx";

    fonts = with pkgs; [
      terminus_font
      source-code-pro
    ];
  };
}

