{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config.allowUnfree = true;
  };
in {
  nixpkgs.config.allowUnfree = true;
  networking.hostName = "thilo-laptop"; 

  system = {
    autoUpgrade.enable = true;
    stateVersion = "19.03";
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "de";
    defaultLocale = "en_US.UTF-8";
  };

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
  };

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
    extraGroups = [ "wheel"  "docker" ]; 
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    enableAllFirmware = true;
    enableRedistributableFirmware = true; 
    pulseaudio.enable = true;
    opengl = {
      enable = true;
      driSupport = true;
    };
  };
  
  sound.enable = true;
                                                           
  boot.kernelPackages = pkgs.linuxPackages_testing;

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
  };
  security.sudo.wheelNeedsPassword = false;

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

