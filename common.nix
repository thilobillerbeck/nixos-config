{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config.allowUnfree = true;
  };
in {
  nixpkgs.config.allowUnfree = true;

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "de";
    defaultLocale = "en_US.UTF-8";
  };

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
  };

  environment.systemPackages = with pkgs; [
    ddate
    file
    htop
    manpages
    tmux
    tree
    wget
    vim
    ( neovim.override {
      configure = {
        packages.myVimPackage = with pkgs.vimPlugins; {
          start = [ nerdtree fugitive vim-nix ];
          opt = [ ];
        };
      };
    })
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
    unstable.nodejs
    watchman
    vagrant
    kubectl
    steam
    python3
    discord
    virtmanager

    unstable.jetbrains.goland
    unstable.jetbrains.idea-ultimate
    unstable.jetbrains.phpstorm
    unstable.jetbrains.pycharm-professional
    unstable.jetbrains.webstorm
  ];

  programs.zsh =  {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "fishy";
    };
    shellAliases = {
      cccda-weechat = "ssh -t avocadoom@shells.darmstadt.ccc.de \"tmux attach -t weechat\"";
    };
    shellInit = ''
      npm set prefix ~/.npm-global
      PATH=$PATH:$HOME/.npm-global/bin
    '';
  };

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

